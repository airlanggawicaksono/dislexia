import 'package:fpdart/fpdart.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/generated_account_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_session_model.dart';
import '../models/auth_user_model.dart';
import '../models/generated_account_model.dart';

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
  Future<Either<Failure, GeneratedAccountEntity>> generateAccount() async {
    try {
      final generated = await _remote.generateAccount();
      // Auto-persist the freshly issued token so the user lands in an
      // authenticated state on the next launch.
      final session = AuthSessionModel(
        accessToken: generated.accessToken,
        tokenType: generated.tokenType,
        expiresIn: generated.expiresIn,
        user: AuthUserModel(
          userId: '',
          accountNumber: generated.accountNumber,
          displayName: generated.displayName,
        ),
      );
      await _local.writeSession(session);
      return Right(generated);
    } on UnauthorizedException catch (_) {
      return const Left(CredentialFailure());
    } on ApiException catch (e) {
      return Left(ServerFailureWithMessage(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

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
    try {
      final session = await _local.readSession();
      if (session == null) {
        return const Left(EmptyFailure());
      }
      return Right(session);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}
