import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/generated_account_entity.dart';
import '../repositories/auth_repository.dart';

/// No-parameter use case for `POST /api/v1/auth/generate`.
class GenerateAccountUseCase
    implements UseCase<GeneratedAccountEntity, NoParams> {
  final AuthRepository _repository;
  const GenerateAccountUseCase(this._repository);

  @override
  Future<Either<Failure, GeneratedAccountEntity>> call(NoParams params) =>
      _repository.generateAccount();
}
