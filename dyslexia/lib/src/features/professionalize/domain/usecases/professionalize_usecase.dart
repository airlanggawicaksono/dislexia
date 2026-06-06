import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/professionalize_result.dart';
import '../repositories/professionalize_repository.dart';

class ProfessionalizeUseCase {
  final ProfessionalizeRepository _repository;
  const ProfessionalizeUseCase(this._repository);

  Future<Either<Failure, ProfessionalizeResult>> call(String text) =>
      _repository.professionalize(text);
}
