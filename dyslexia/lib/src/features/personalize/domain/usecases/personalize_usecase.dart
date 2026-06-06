import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/personalize_result.dart';
import '../repositories/personalize_repository.dart';

class PersonalizeUseCase {
  final PersonalizeRepository _repository;
  const PersonalizeUseCase(this._repository);

  Future<Either<Failure, PersonalizeResult>> call(String text) =>
      _repository.personalize(text);
}
