import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';

abstract class UploadRepository {
  Future<Either<Failure, DocumentEntity>> pickAndExtract();
}
