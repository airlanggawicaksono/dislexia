import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/summary_level.dart';

abstract class SummarizeRepository {
  /// Streams generated summary chunks. Each `right` is one chunk of text;
  /// a `left` signals failure (the stream ends after the first failure).
  Stream<Either<Failure, String>> summarizeStream(
    String text, {
    SummaryLevel? level,
  });
}
