import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/failure_converter.dart';
import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/generated_account_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/generate_account_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Orchestrates the auth flow. The BLoC is the only place that knows
/// about use-cases — the UI just dispatches events and renders states.
///
/// State machine:
///
///   AuthInitial ─RestoreSessionEvent─> AuthLoading
///   AuthLoading (success)            ─> Authenticated
///   AuthLoading (no session)         ─> Unauthenticated
///   Unauthenticated ─LoginEvent─> AuthLoading
///   Unauthenticated ─GenerateAccountEvent─> AuthLoading
///   Authenticated    ─LogoutEvent─> Unauthenticated
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GenerateAccountUseCase _generateAccount;
  final LoginUseCase _login;
  final LogoutUseCase _logout;
  final RestoreSessionUseCase _restoreSession;

  AuthBloc({
    required GenerateAccountUseCase generateAccount,
    required LoginUseCase login,
    required LogoutUseCase logout,
    required RestoreSessionUseCase restoreSession,
  })  : _generateAccount = generateAccount,
        _login = login,
        _logout = logout,
        _restoreSession = restoreSession,
        super(const AuthInitial()) {
    on<RestoreSessionEvent>(_onRestoreSession);
    on<GenerateAccountEvent>(_onGenerateAccount);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  /// Direct setter used by the DI factory when the app has just been
  /// restored from storage and we want to seed the bloc synchronously.
  /// Keeping it as a function (not a state mutation) means the BLoC's
  /// normal lifecycle still applies.
  void seedAuthenticated(AuthSessionEntity session) {
    emit(Authenticated(session));
  }

  Future<void> _onRestoreSession(
      RestoreSessionEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _restoreSession.call(const NoParams());
    result.fold(
      (failure) {
        // EmptyFailure == "no stored session" — that's the normal
        // first-launch case, so just transition to Unauthenticated
        // without an error message.
        if (failure is EmptyFailure) {
          emit(const Unauthenticated());
        } else {
          emit(Unauthenticated(errorMessage: mapFailureToMessage(failure)));
        }
      },
      (session) {
        if (session == null) {
          emit(const Unauthenticated());
        } else {
          emit(Authenticated(session));
        }
      },
    );
  }

  Future<void> _onGenerateAccount(
      GenerateAccountEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result =
        await _generateAccount.call(const NoParams());
    result.fold(
      (failure) {
        emit(Unauthenticated(errorMessage: mapFailureToMessage(failure)));
      },
      (GeneratedAccountEntity generated) {
        // Don't auto-authenticate after generate — the user must see
        // and confirm they've saved the account number first. The auth
        // page stays in Unauthenticated with the pending account number
        // visible, and dispatches a `RestoreSessionEvent` once the user
        // taps "I've saved it".
        emit(Unauthenticated(
          pendingAccountNumber: generated.accountNumber,
          pendingDisplayName: generated.displayName,
        ));
      },
    );
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _login.call(LoginParams(event.accountNumber));
    result.fold(
      (failure) {
        emit(Unauthenticated(errorMessage: mapFailureToMessage(failure)));
      },
      (AuthSessionEntity session) {
        emit(Authenticated(session));
      },
    );
  }

  Future<void> _onLogout(
      LogoutEvent event, Emitter<AuthState> emit) async {
    final result = await _logout.call(const NoParams());
    result.fold(
      (failure) {
        // Logout is best-effort: even if wiping storage failed we want
        // the UI to drop back to the auth page.
        emit(Unauthenticated(errorMessage: mapFailureToMessage(failure)));
      },
      (_) {
        emit(const Unauthenticated());
      },
    );
  }
}
