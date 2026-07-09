import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/lens_repository.dart';

class StartLensUseCase {
  final LensRepository _repository;
  const StartLensUseCase(this._repository);

  Future<Either<Failure, Unit>> call() => _repository.start();
}
