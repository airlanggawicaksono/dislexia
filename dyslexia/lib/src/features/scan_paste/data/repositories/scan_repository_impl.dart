import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_datasource.dart';

class ScanRepositoryImpl implements ScanRepository {
  final ScanDatasourceImpl _datasource;
  ScanRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, DocumentEntity>> scanFromCamera(
      String imagePath) async {
    try {
      final result = await _datasource.scanFromCamera(imagePath);
      if (result.text == null || result.text!.isEmpty) {
        return Left(TextExtractionFailure());
      }
      return Right(result);
    } catch (_) {
      return Left(OcrFailure());
    }
  }
}
