import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/summary_level.dart';
import '../repositories/summarize_repository.dart';

class SummarizeUseCase {
  final SummarizeRepository _repository;
  const SummarizeUseCase(this._repository);

  Stream<Either<Failure, String>> call(
    String text, {
    SummaryLevel? level,
  }) =>
      _repository.summarizeStream(text, level: level);
}
