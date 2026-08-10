import 'dart:async';
import 'dart:convert';

import 'package:fetch_client/fetch_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../features/auth/presentation/bloc/token_holder.dart';
import 'api_exception.dart';
import 'api_helper.dart';
import 'api_url.dart';

/// Turns a decoded JSON object into a domain/model instance.
typedef JsonParser<T> = T Function(Map<String, dynamic> json);

/// Thin, reusable HTTP layer that every remote datasource ingests through.
///
/// It sits on top of [ApiHelper] (the single shared Dio + [AuthInterceptor]
/// that already stamps the bearer token and maps status codes to exceptions)
/// and adds the ergonomics datasources kept re-implementing by hand:
///
///   * **Path-relative calls** — pass `/me/history`, not
///     `'${ApiUrl.baseUrl}/me/history'`. Absolute URLs (`http...`) pass
///     through untouched, so one-off hosts still work.
///   * **Per-request headers** — the `headers` arg is merged on top of the
///     interceptor defaults, for endpoints that need extra ingest headers.
///   * **Typed parsing** — [getObject]/[getList]/[postObject] take a
///     [JsonParser] and hand back models instead of raw maps.
///
/// Register once (see DI) and inject it wherever a datasource talks to the
/// backend. Auth is automatic; callers never touch tokens.
class ApiClient {
  final ApiHelper _api;
  const ApiClient(this._api);

  /// Resolve a path against [ApiUrl.baseUrl]. Absolute URLs are left as-is.
  String _resolve(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final sep = path.startsWith('/') ? '' : '/';
    return '${ApiUrl.baseUrl}$sep$path';
  }

  // ---- raw map helpers ------------------------------------------------

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _api.execute(
        method: Method.get,
        url: _resolve(path),
        queryParameters: query,
        headers: headers,
      );

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _api.execute(
        method: Method.post,
        url: _resolve(path),
        data: body,
        queryParameters: query,
        headers: headers,
      );

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _api.execute(
        method: Method.put,
        url: _resolve(path),
        data: body,
        queryParameters: query,
        headers: headers,
      );

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _api.execute(
        method: Method.patch,
        url: _resolve(path),
        data: body,
        queryParameters: query,
        headers: headers,
      );

  Future<Map<String, dynamic>> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) =>
      _api.execute(
        method: Method.delete,
        url: _resolve(path),
        data: body,
        queryParameters: query,
        headers: headers,
      );

  // ---- typed helpers --------------------------------------------------

  /// GET a single object and parse it.
  Future<T> getObject<T>(
    String path, {
    required JsonParser<T> parse,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    final json = await get(path, query: query, headers: headers);
    return parse(json);
  }

  /// GET a list wrapped under [itemsKey] (backend list DTOs use `items`).
  Future<List<T>> getList<T>(
    String path, {
    required JsonParser<T> parse,
    String itemsKey = 'items',
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    final json = await get(path, query: query, headers: headers);
    final raw = (json[itemsKey] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => parse(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST a body and parse the object response.
  Future<T> postObject<T>(
    String path, {
    required JsonParser<T> parse,
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    final json = await post(path, body: body, query: query, headers: headers);
    return parse(json);
  }

  // ---- streaming (SSE) -------------------------------------------

  /// POST [body] to [path] and stream the backend's Server-Sent Events
  /// as decoded chunk-content strings.
  ///
  /// The feature endpoints (`/process-stream`) reply with
  /// `text/event-stream`; each event is `data: {chunk JSON}\n\n`, and the
  /// chunk's `content` field carries the next piece of generated text.
  /// Each event's content is emitted in order — callers append to build
  /// the full result live.
  ///
  /// Uses a fetch-based client on web instead of Dio or XHR because both
  /// buffer the whole response body: Dio's web adapter (XHR
  /// `arraybuffer`) and `package:http`'s web default `BrowserClient`
  /// (XMLHttpRequest) only deliver everything once the server closes the
  /// stream, so the UI would show one big jump at the end instead of
  /// live chunks. The browser fetch API exposes a `ReadableStream`, so
  /// [FetchClient] emits each SSE event as it arrives; native keeps
  /// `package:http`'s dart:io client, which streams fine.
  ///
  /// Throws the same [ApiException]s as [post] for non-2xx statuses;
  /// mid-stream failures surface as a stream error.
  Stream<String> postStream(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async* {
    var uri = Uri.parse(_resolve(path));
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream';
    final token = TokenHolder.instance.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (headers != null) {
      request.headers.addAll(
          headers.map((key, value) => MapEntry(key, value.toString())));
    }
    if (body != null) request.body = jsonEncode(body);

    // On web, package:http's default BrowserClient is XMLHttpRequest-based
    // and buffers the entire body until the stream closes; the browser
    // fetch API (via FetchClient) delivers chunks incrementally. FetchClient
    // defaults to `mode: noCors`, which makes a cross-origin response
    // opaque (status 0, unreadable body) and strips the Authorization
    // header — `cors` is required to read the SSE stream.
    final client = kIsWeb ? FetchClient(mode: RequestMode.cors) : http.Client();
    http.StreamedResponse response;
    // Header-receipt bound mirrors the Dio client's 20s connect timeout so
    // a dead/slow server errors out instead of leaving the UI loading
    // forever. The SSE body stream itself is intentionally NOT timed out —
    // a long generation must be allowed to run its course.
    try {
      response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      client.close();
      throw FetchDataException('No Internet connection');
    } catch (_) {
      client.close();
      rethrow;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = await response.stream.bytesToString();
      client.close();
      throw _exceptionForStatus(response.statusCode, errorBody);
    }
    // try/finally (not whenComplete — Stream has no such method) so the
    // client is released when the body stream finishes, errors, or the
    // consumer cancels the subscription.
    try {
      yield* response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.startsWith('data: '))
          .map(_sseContent)
          .where((chunk) => chunk.isNotEmpty);
    } finally {
      client.close();
    }
  }

  /// Parse one SSE `data:` payload into its `content` field. Non-JSON
  /// lines (keep-alives, `[DONE]`, comments) yield an empty string that
  /// [postStream] filters out.
  static String _sseContent(String line) {
    final payload = line.substring('data: '.length).trim();
    if (payload.isEmpty || payload == '[DONE]') return '';
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return decoded['content']?.toString() ?? '';
      }
    } catch (_) {
      // Not JSON — skip.
    }
    return '';
  }

  /// Map an HTTP status to the same [ApiException]s the Dio path throws.
  static Exception _exceptionForStatus(int status, String body) {
    String detail(String fallback) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          final msg = decoded['detail'] ?? decoded['message'];
          if (msg != null) return msg.toString();
        }
      } catch (_) {}
      return fallback;
    }

    switch (status) {
      case 400:
        return BadRequestException(detail('Bad request'));
      case 401:
        return UnauthorizedException(detail('Not authenticated'));
      case 403:
        return ForbiddenException(detail('Forbidden'));
      case 404:
        return NotFoundException(detail('Not found'));
      case 422:
        return UnprocessableContentException(detail('Unprocessable content'));
      case 500:
        return InternalServerException(detail('Internal server error'));
      default:
        return FetchDataException(
            'Error occurred while communicating with server (HTTP $status)');
    }
  }
}
