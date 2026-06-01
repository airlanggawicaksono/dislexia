import 'package:dio/dio.dart';
import 'package:dyslexia/src/core/api/api_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tiny request recorder so we can inspect what [AuthInterceptor]
/// forwards to the next handler without having to spin up a real
/// [RequestInterceptorHandler].
class _RecordingHandler extends RequestInterceptorHandler {
  _RecordingHandler() : super(requestOptions: RequestOptions(path: '/'));
  RequestOptions? last;

  @override
  void next(RequestOptions requestOptions) {
    last = requestOptions;
    super.next(requestOptions);
  }
}

void main() {
  group('AuthInterceptor.onRequest', () {
    test('injects Bearer token when a token is available', () {
      final interceptor = AuthInterceptor(
        tokenProvider: () => 'abc123',
      );
      final options = RequestOptions(path: '/me');
      final handler = _RecordingHandler();

      interceptor.onRequest(options, handler);

      expect(handler.last?.headers['Authorization'], 'Bearer abc123');
      expect(handler.last?.baseUrl, isNotEmpty);
    });

    test('skips Authorization when token is null', () {
      final interceptor = AuthInterceptor(
        tokenProvider: () => null,
      );
      final options = RequestOptions(path: '/me');
      final handler = _RecordingHandler();

      interceptor.onRequest(options, handler);

      expect(handler.last?.headers.containsKey('Authorization'), isFalse);
    });

    test('does not inject token on /auth/generate', () {
      final interceptor = AuthInterceptor(
        tokenProvider: () => 'abc123',
      );
      final options = RequestOptions(path: '/auth/generate');
      final handler = _RecordingHandler();

      interceptor.onRequest(options, handler);

      expect(handler.last?.headers.containsKey('Authorization'), isFalse);
    });

    test('does not inject token on /auth/login', () {
      final interceptor = AuthInterceptor(
        tokenProvider: () => 'abc123',
      );
      final options = RequestOptions(path: '/auth/login');
      final handler = _RecordingHandler();

      interceptor.onRequest(options, handler);

      expect(handler.last?.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('AuthInterceptor.onError', () {
    test('fires onUnauthorized on 401 for a protected route', () {
      RequestOptions? captured;
      final interceptor = AuthInterceptor(
        tokenProvider: () => 'abc123',
        onUnauthorized: (req) => captured = req,
      );

      final err = DioException(
        requestOptions: RequestOptions(path: '/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/me'),
          statusCode: 401,
        ),
      );
      final next = _RecordingHandler();
      interceptor.onError(err, ErrorInterceptorHandler());

      expect(captured, isNotNull);
      expect(captured?.path, '/me');
    });

    test('does not fire onUnauthorized on 401 for /auth/login', () {
      var fired = false;
      final interceptor = AuthInterceptor(
        tokenProvider: () => 'abc123',
        onUnauthorized: (_) => fired = true,
      );

      final err = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
        ),
      );
      interceptor.onError(err, ErrorInterceptorHandler());
      expect(fired, isFalse);
    });

    test('does not fire onUnauthorized for non-401 errors', () {
      var fired = false;
      final interceptor = AuthInterceptor(
        tokenProvider: () => 'abc123',
        onUnauthorized: (_) => fired = true,
      );
      final err = DioException(
        requestOptions: RequestOptions(path: '/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/me'),
          statusCode: 500,
        ),
      );
      interceptor.onError(err, ErrorInterceptorHandler());
      expect(fired, isFalse);
    });

    test('works without an onUnauthorized callback', () {
      final interceptor = AuthInterceptor(
        tokenProvider: () => 'abc123',
      );
      final err = DioException(
        requestOptions: RequestOptions(path: '/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/me'),
          statusCode: 401,
        ),
      );
      // Should not throw even though no callback was registered.
      expect(() => interceptor.onError(err, ErrorInterceptorHandler()),
          returnsNormally);
    });
  });
}
