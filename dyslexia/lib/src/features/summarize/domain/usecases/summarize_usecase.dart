import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/summarize_result.dart';
import '../repositories/summarize_repository.dart';

class SummarizeUseCase {
  final SummarizeRepository _repository;
  const SummarizeUseCase(this._repository);

  Future<Either<Failure, SummarizeResult>> call(String text) =>
      _repository.summarize(text);
}
