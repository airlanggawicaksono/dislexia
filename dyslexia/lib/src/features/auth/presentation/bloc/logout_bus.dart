import 'dart:async';

/// Global, app-wide signal that the current session has been rejected
/// by the server (HTTP 401). The [AuthInterceptor] pings this bus on
/// every unauthorised response; the [AuthBloc] host (currently
/// `_DesktopShellGate` in `main.dart`) listens and dispatches a
/// [LogoutEvent] on its bloc instance.
///
/// We use a broadcast [Stream] rather than a singleton [AuthBloc] so:
///
/// - the [AuthBloc] can stay a `factory` (fresh bloc per BlocProvider,
///   no stale state on hot-restart);
/// - the interceptor doesn't have to know about Flutter widget
///   lifecycles — it just fires and forgets;
/// - the host that owns the bloc subscribes once at app start and
///   cleans up on dispose, just like any other stream listener.
class LogoutBus {
  LogoutBus._();

  /// Backing controller. `null` until the first listener subscribes
  /// (we only allocate it then) so the bus is essentially free at
  /// boot if nothing ever listens.
  static StreamController<void>? _controller;

  static Stream<void> get stream {
    _controller ??= StreamController<void>.broadcast();
    return _controller!.stream;
  }

  /// Fire the bus. Called from the [AuthInterceptor] on 401. Safe to
  /// call before any listener is attached — the event is dropped
  /// (which is fine: if nobody is listening, nobody is logged in).
  static void fire() {
    final c = _controller;
    if (c == null || c.isClosed) return;
    if (!c.hasListener) return;
    c.add(null);
  }

  /// For tests / hot-restart cleanup.
  static void reset() {
    _controller?.close();
    _controller = null;
  }
}
