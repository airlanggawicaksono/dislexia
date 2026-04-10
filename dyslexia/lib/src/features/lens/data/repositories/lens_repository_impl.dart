import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/entities/document_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/lens_frame_entity.dart';
import '../../domain/repositories/lens_repository.dart';
import '../datasources/lens_datasource.dart';

class LensRepositoryImpl implements LensRepository {
  final LensDatasourceImpl _datasource;
  LensRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, DocumentEntity>> captureAndExtract() async {
    try {
      return Right(await _datasource.captureAndExtract());
    } catch (_) {
      return Left(OcrFailure());
    }
  }

  @override
  Future<Either<Failure, LensFrameEntity>> analyzeFrame(AnalysisImage img) async {
    try {
      return Right(await _datasource.analyzeFrame(img));
    } catch (_) {
      return Left(OcrFailure());
    }
  }
}
