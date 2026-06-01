import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session_entity.dart';
import '../repositories/auth_repository.dart';

/// Reads the persisted session from secure storage on app start.
/// `null` (mapped to `EmptyFailure`) means "never logged in" — the UI
/// should show the auth page.
class RestoreSessionUseCase
    implements UseCase<AuthSessionEntity?, NoParams> {
  final AuthRepository _repository;
  const RestoreSessionUseCase(this._repository);

  @override
  Future<Either<Failure, AuthSessionEntity?>> call(NoParams params) =>
      _repository.restoreSession();
}
