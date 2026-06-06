import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/define_result.dart';
import '../repositories/define_repository.dart';

class DefineUseCase {
  final DefineRepository _repository;
  const DefineUseCase(this._repository);

  Future<Either<Failure, DefineResult>> call(String text) =>
      _repository.define(text);
}
