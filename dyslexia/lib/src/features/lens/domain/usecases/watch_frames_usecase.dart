import '../entities/recognized_frame.dart';
import '../repositories/lens_repository.dart';

class WatchFramesUseCase {
  final LensRepository _repository;
  const WatchFramesUseCase(this._repository);

  Stream<RecognizedFrame> call() => _repository.frames;
}
