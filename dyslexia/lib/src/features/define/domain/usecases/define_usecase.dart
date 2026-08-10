import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/define_level.dart';
import '../repositories/define_repository.dart';

class DefineUseCase {
  final DefineRepository _repository;
  const DefineUseCase(this._repository);

  Stream<Either<Failure, String>> call(
    String text, {
    DefineLevel? level,
  }) =>
      _repository.defineStream(text, level: level);
}
