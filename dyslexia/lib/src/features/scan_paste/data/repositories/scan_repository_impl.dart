import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_datasource.dart';

class ScanRepositoryImpl implements ScanRepository {
  final ScanDatasourceImpl _datasource;
  ScanRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, DocumentEntity>> scanFromCamera() async {
    try {
      final result = await _datasource.scanFromCamera();
      return Right(result);
    } catch (_) {
      return Left(OcrFailure());
    }
  }
}
