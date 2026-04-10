import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/entities/document_entity.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lens_frame_entity.dart';

abstract class LensRepository {
  Future<Either<Failure, DocumentEntity>> captureAndExtract();
  Future<Either<Failure, LensFrameEntity>> analyzeFrame(AnalysisImage img);
}
