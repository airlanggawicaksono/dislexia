import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/entities/document_entity.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/scan_repository.dart';

class ScanParams extends Equatable {
  final String imagePath;
  const ScanParams(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class ScanTextUseCase implements UseCase<DocumentEntity, ScanParams> {
  final ScanRepository _repository;
  ScanTextUseCase(this._repository);

  @override
  Future<Either<Failure, DocumentEntity>> call(ScanParams params) =>
      _repository.scanFromCamera(params.imagePath);
}
