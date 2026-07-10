import 'package:fpdart/fpdart.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_session_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Server failure that carries the human-readable message from the API
/// (e.g. "Invalid account number"). Distinct from the empty
/// [ServerFailure] in `core/errors/failures.dart` so the BLoC can show
/// the backend's text instead of a generic message.
class ServerFailureWithMessage extends Failure {
  final String message;
  const ServerFailureWithMessage(this.message);

  @override
  List<Object> get props => [message];
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource _local;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required AuthLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<Either<Failure, AuthSessionEntity>> login(
      String accountNumber) async {
    try {
      final session = await _remote.login(accountNumber);
      await _local.writeSession(session);
      return Right(session);
    } on UnauthorizedException catch (_) {
      return const Left(CredentialFailure());
    } on ApiException catch (e) {
      return Left(ServerFailureWithMessage(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _local.clearSession();
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, AuthSessionEntity?>> restoreSession() async {
    final AuthSessionEntity? session;
    try {
      session = await _local.readSession();
    } catch (_) {
      return const Left(CacheFailure());
    }
    if (session == null) {
      return const Left(EmptyFailure());
    }
    // Verify the account still exists / is active before trusting the stored
    // token (mobile uses a no-expiry JWT, so a deleted account would otherwise
    // stay "logged in" until its first feature call).
    try {
      await _remote.validateSession(session.accessToken);
    } on UnauthorizedException {
      // 401 → account gone / deactivated → drop the dead session.
      await _local.clearSession();
      return const Left(EmptyFailure());
    } catch (_) {
      // Network / server hiccup → stay signed in (offline tolerant); the next
      // authenticated request re-checks and logs out on a real 401.
      return Right(session);
    }
    return Right(session);
  }
}
