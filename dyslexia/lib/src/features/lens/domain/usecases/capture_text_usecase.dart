import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/lens_repository.dart';

class CaptureTextUseCase implements UseCase<DocumentEntity, NoParams> {
  final LensRepository _repository;
  CaptureTextUseCase(this._repository);

  @override
  Future<Either<Failure, DocumentEntity>> call(NoParams params) =>
      _repository.captureAndExtract();
}
