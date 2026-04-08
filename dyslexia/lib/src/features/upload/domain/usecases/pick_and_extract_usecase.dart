import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/upload_repository.dart';

class PickAndExtractUseCase implements UseCase<DocumentEntity, NoParams> {
  final UploadRepository _repository;
  PickAndExtractUseCase(this._repository);

  @override
  Future<Either<Failure, DocumentEntity>> call(NoParams params) =>
      _repository.pickAndExtract();
}
