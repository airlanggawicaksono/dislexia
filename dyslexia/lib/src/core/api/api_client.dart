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
}
