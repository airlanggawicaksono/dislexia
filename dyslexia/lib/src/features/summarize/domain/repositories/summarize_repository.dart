import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/summarize_result.dart';
import '../entities/summary_level.dart';

abstract class SummarizeRepository {
  Future<Either<Failure, SummarizeResult>> summarize(
    String text, {
    SummaryLevel? level,
  });
}
