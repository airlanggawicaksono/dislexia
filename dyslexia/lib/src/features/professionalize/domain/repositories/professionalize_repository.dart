import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

abstract class ProfessionalizeRepository {
  /// Streams generated rewritten-text chunks. Each `right` is one chunk; a
  /// `left` signals failure (the stream ends after the first failure).
  Stream<Either<Failure, String>> professionalizeStream(
    String text, {
    String? recipientName,
    String? senderName,
  });
}
