import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/scan_repository.dart';

class ScanTextUseCase implements UseCase<DocumentEntity, NoParams> {
  final ScanRepository _repository;
  ScanTextUseCase(this._repository);

  @override
  Future<Either<Failure, DocumentEntity>> call(NoParams params) =>
      _repository.scanFromCamera();
}
