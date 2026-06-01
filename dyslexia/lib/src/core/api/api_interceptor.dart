import 'package:dio/dio.dart';

import '../utils/logger.dart';
import 'api_url.dart';

/// Synchronous getter for the current access token. Called by the
/// interceptor on every request so we always see the freshest value
/// without having to rebuild the Dio instance when the user logs in
/// or out.
typedef TokenProvider = String? Function();

/// Called when the API replies with a 401 on an authenticated request.
/// Receives the original [RequestOptions] so callers can inspect which
/// call triggered the rejection.
typedef OnUnauthorized = void Function(RequestOptions request);

/// AuthInterceptor is responsible for two things:
///
/// 1. Injecting the `Authorization: Bearer <token>` header on every
///    outgoing request that has a token available.
/// 2. Reacting to `401 Unauthorized` responses by notifying the host
///    app (typically a BLoC) so it can clear the session and bounce
///    the user back to the login screen.
///
/// The bootstrap auth endpoints (`/auth/generate`, `/auth/login`) are
/// treated specially:
///
/// - On the way *out*, the `Authorization` header is **never** injected
///   — these calls happen before (or instead of) a session existing.
/// - On the way *back*, a 401 is **not** interpreted as "your session
///   died" — it just means the credentials you sent were wrong, and
///   the caller wants to surface that to the user.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenProvider tokenProvider,
    OnUnauthorized? onUnauthorized,
  })  : _tokenProvider = tokenProvider,
        _onUnauthorized = onUnauthorized;

  final TokenProvider _tokenProvider;
  final OnUnauthorized? _onUnauthorized;

  /// Paths that are allowed to flow through without a token attached
  /// and without triggering a forced logout on 401. The match is done
  /// on the *path tail* so it works regardless of the configured
  /// [ApiUrl.baseUrl].
  static const _bootstrapPaths = <String>{
    '/auth/generate',
    '/auth/login',
  };

  bool _isBootstrapRequest(RequestOptions options) {
    final path = options.path;
    if (path.isEmpty) return false;
    for (final p in _bootstrapPaths) {
      if (path == p || path.endsWith(p)) return true;
    }
    return false;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Always stamp the configured base URL so callers can pass relative
    // paths if they want.
    options.baseUrl = ApiUrl.baseUrl;

    // Auth-bootstrap endpoints must never carry a token — they're
    // literally the calls that mint or refresh one.
    if (_isBootstrapRequest(options)) {
      super.onRequest(options, handler);
      return;
    }

    final token = _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (status == 401 &&
        !_isBootstrapRequest(err.requestOptions) &&
        _onUnauthorized != null) {
      logger.w('AuthInterceptor: 401 received on '
          '${err.requestOptions.method} ${err.requestOptions.path} '
          '— firing onUnauthorized');
      _onUnauthorized!(err.requestOptions);
    } else if (status == 401) {
      logger.w('AuthInterceptor: 401 on bootstrap path '
          '${err.requestOptions.path} — not forcing logout');
    } else {
      logger.e('AuthInterceptor: error status=$status '
          'on ${err.requestOptions.path}: ${err.message}');
    }
    super.onError(err, handler);
  }
}
