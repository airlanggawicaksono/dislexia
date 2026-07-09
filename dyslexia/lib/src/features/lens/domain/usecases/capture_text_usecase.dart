import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/lens_repository.dart';

/// Capture a sharp still and return its recognised text (higher accuracy
/// than the live frames).
class CaptureTextUseCase {
  final LensRepository _repository;
  const CaptureTextUseCase(this._repository);

  Future<Either<Failure, String>> call() => _repository.captureText();
}
