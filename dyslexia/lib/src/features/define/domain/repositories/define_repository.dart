import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/define_level.dart';

abstract class DefineRepository {
  /// Streams generated definition chunks. Each `right` is one chunk of text;
  /// a `left` signals failure (the stream ends after the first failure).
  Stream<Either<Failure, String>> defineStream(
    String text, {
    DefineLevel? level,
  });
}
