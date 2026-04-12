import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';
import '../../domain/repositories/upload_repository.dart';
import '../datasources/upload_datasource_impl.dart';

class UploadRepositoryImpl implements UploadRepository {
  final UploadDatasourceImpl _datasource;
  UploadRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, DocumentEntity>> pickAndExtract() async {
    try {
      final result = await _datasource.pickAndExtract();
      return Right(result);
    } catch (_) {
      return Left(FilePickerFailure());
    }
  }
}
