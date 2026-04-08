import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';

abstract class LensRepository {
  Future<Either<Failure, DocumentEntity>> captureAndExtract();
}
