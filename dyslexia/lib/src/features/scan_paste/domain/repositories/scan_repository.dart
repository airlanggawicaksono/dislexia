import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';

abstract class ScanRepository {
  Future<Either<Failure, DocumentEntity>> scanFromCamera();
}
