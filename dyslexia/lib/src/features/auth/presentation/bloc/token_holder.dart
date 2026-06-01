/// Tiny in-memory cache of the *currently* authenticated access token.
///
/// The [AuthInterceptor] is constructed once and lives for the entire
/// app lifetime, but [Dio] calls its interceptor hooks *synchronously*
/// on every request. There's no way to `await` reading secure storage
/// inside an interceptor without blocking the event loop, so the
/// AuthBloc — which already knows the token from the login / restore
/// flow — keeps this holder in sync with its [Authenticated] /
/// [Unauthenticated] state. The interceptor then just does
/// `TokenHolder.instance.token` and gets the latest value instantly.
///
/// Only the latest token is kept in memory; we don't try to mirror
/// the full [AuthSessionEntity] here because the interceptor only
/// needs the bearer string.
class TokenHolder {
  TokenHolder._();

  /// Process-wide singleton. There's only ever one auth session at a
  /// time, so a single global cell is exactly what we want.
  static final TokenHolder instance = TokenHolder._();

  String? _token;

  /// The bearer token to attach to the next request, or `null` if the
  /// user is signed out.
  String? get token => _token;

  /// Replace the cached token. Called by [AuthBloc] on
  /// [Authenticated] and cleared on [Unauthenticated].
  void set(String? value) {
    _token = (value == null || value.isEmpty) ? null : value;
  }

  /// Clear the cached token. Equivalent to `set(null)`.
  void clear() => set(null);
}
