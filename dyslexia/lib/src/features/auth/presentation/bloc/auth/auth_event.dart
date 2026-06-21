part of 'auth_bloc.dart';

/// Base class for everything that can be dispatched at [AuthBloc].
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispatched once on app start. Asks the repository to re-hydrate the
/// session from secure storage.
class RestoreSessionEvent extends AuthEvent {
  const RestoreSessionEvent();
}

/// Hits `POST /auth/generate` to mint a brand-new account. The result
/// carries the 6-digit account number the user MUST save.
class GenerateAccountEvent extends AuthEvent {
  const GenerateAccountEvent();
}

/// Hits `POST /auth/login` with the user-entered 6-digit number.
class LoginEvent extends AuthEvent {
  final String accountNumber;
  const LoginEvent(this.accountNumber);

  @override
  List<Object?> get props => [accountNumber];
}

/// Clears the persisted session and resets the bloc to unauthenticated.
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
