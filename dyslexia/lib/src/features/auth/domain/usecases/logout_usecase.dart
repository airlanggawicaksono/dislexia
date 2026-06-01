import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Wipes the persisted session from secure storage.
class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository _repository;
  const LogoutUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      _repository.logout();
}
