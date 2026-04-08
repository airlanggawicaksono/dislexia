import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';
import '../../domain/repositories/lens_repository.dart';
import '../datasources/lens_datasource.dart';

class LensRepositoryImpl implements LensRepository {
  final LensDatasourceImpl _datasource;
  LensRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, DocumentEntity>> captureAndExtract() async {
    try {
      final result = await _datasource.captureAndExtract();
      return Right(result);
    } catch (_) {
      return Left(OcrFailure());
    }
  }
}
