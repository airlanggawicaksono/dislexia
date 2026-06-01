import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session_entity.dart';
import '../entities/generated_account_entity.dart';

/// Auth gateway. The presentation layer talks to this — never to the
/// remote/local datasources directly. Methods return `Either<Failure, T>`
/// so the BLoC can fold them into states without try/catch noise.
abstract class AuthRepository {
  /// `POST /api/v1/auth/generate` — create a brand-new account. The
  /// returned `accountNumber` is the only credential for the account and
  /// MUST be shown to the user so they can save it.
  Future<Either<Failure, GeneratedAccountEntity>> generateAccount();

  /// `POST /api/v1/auth/login` — exchange a 16-digit account number for
  /// a session. The session is persisted to secure storage before
  /// returning.
  Future<Either<Failure, AuthSessionEntity>> login(String accountNumber);

  /// Wipe the persisted session. Always succeeds.
  Future<Either<Failure, void>> logout();

  /// Re-hydrate the session from secure storage on app start. Returns
  /// `null` (mapped to `EmptyFailure`) if no token was previously stored
  /// or the stored blob is unparseable.
  Future<Either<Failure, AuthSessionEntity?>> restoreSession();
}
