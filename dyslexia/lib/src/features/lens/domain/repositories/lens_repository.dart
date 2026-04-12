import 'package:fpdart/fpdart.dart';

import '../../../../core/entities/document_entity.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lens_frame_entity.dart';
import '../entities/lens_scan_payload_entity.dart';

abstract class LensRepository {
  Future<Either<Failure, DocumentEntity>> captureAndExtract();
  Future<Either<Failure, LensFrameEntity>> analyzeFrame(
    LensScanPayloadEntity payload,
  );
}
