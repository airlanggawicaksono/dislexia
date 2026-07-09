import 'package:camera/camera.dart';

import '../repositories/lens_repository.dart';

/// Exposes the active [CameraController] for the preview widget. Kept as a
/// use case so the bloc/page never reach into the repository directly.
class LensPreviewUseCase {
  final LensRepository _repository;
  const LensPreviewUseCase(this._repository);

  CameraController? call() => _repository.previewController;
}
