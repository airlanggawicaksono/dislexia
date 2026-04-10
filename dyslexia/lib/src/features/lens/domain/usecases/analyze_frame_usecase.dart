import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/lens_frame_entity.dart';
import '../repositories/lens_repository.dart';

class AnalyzeFrameParams {
  final AnalysisImage image;
  const AnalyzeFrameParams(this.image);
}

class AnalyzeFrameUseCase {
  final LensRepository _repository;
  AnalyzeFrameUseCase(this._repository);

  Future<Either<Failure, LensFrameEntity>> call(AnalyzeFrameParams params) =>
      _repository.analyzeFrame(params.image);
}
