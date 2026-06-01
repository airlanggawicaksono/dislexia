part of 'auth_bloc.dart';

/// High-level state of the auth subsystem.
///
/// - [AuthInitial]   — bloc has been created, no work has happened yet.
/// - [AuthLoading]   — a network call is in flight (generate / login /
///                     restore).
/// - [Authenticated] — we have a valid session. The UI hides the auth
///                     page and shows the app shell.
/// - [Unauthenticated] — no session. The UI shows the auth page.
/// - [AuthError]     — last operation failed; carry the message for the
///                     UI to display, but keep the bloc in whichever
///                     "logged-in-ness" bucket it was in before
///                     (authenticated stays authenticated, just with an
///                     error message visible).
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final AuthSessionEntity session;
  const Authenticated(this.session);

  @override
  List<Object?> get props => [session];
}

class Unauthenticated extends AuthState {
  /// Set to a non-null message when the most recent attempt failed so
  /// the auth page can surface the error.
  final String? errorMessage;
  /// Set to the freshly generated account number right after a
  /// successful `GenerateAccountEvent` — the user must save it before
  /// the auth page is dismissed.
  final String? pendingAccountNumber;
  final String? pendingDisplayName;

  const Unauthenticated({
    this.errorMessage,
    this.pendingAccountNumber,
    this.pendingDisplayName,
  });

  @override
  List<Object?> get props =>
      [errorMessage, pendingAccountNumber, pendingDisplayName];

  Unauthenticated copyWith({
    String? errorMessage,
    String? pendingAccountNumber,
    String? pendingDisplayName,
    bool clearError = false,
    bool clearPending = false,
  }) {
    return Unauthenticated(
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingAccountNumber: clearPending
          ? null
          : (pendingAccountNumber ?? this.pendingAccountNumber),
      pendingDisplayName: clearPending
          ? null
          : (pendingDisplayName ?? this.pendingDisplayName),
    );
  }
}

/// Used internally for error states that don't change the auth status
/// (e.g. logout failed). The bloc surfaces these via [BlocListener].
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
