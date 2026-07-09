import '../repositories/lens_repository.dart';

class StopLensUseCase {
  final LensRepository _repository;
  const StopLensUseCase(this._repository);

  Future<void> call() => _repository.stop();
}
