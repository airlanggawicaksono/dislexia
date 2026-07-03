import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/summarize_result.dart';
import '../entities/summary_level.dart';
import '../repositories/summarize_repository.dart';

class SummarizeUseCase {
  final SummarizeRepository _repository;
  const SummarizeUseCase(this._repository);

  Future<Either<Failure, SummarizeResult>> call(
    String text, {
    SummaryLevel? level,
  }) =>
      _repository.summarize(text, level: level);
}
