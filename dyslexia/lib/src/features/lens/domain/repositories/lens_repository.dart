import 'package:camera/camera.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/recognized_frame.dart';

/// Live text-recognition over the camera feed.
///
/// Note: [previewController] intentionally exposes the camera plugin's
/// [CameraController] so the page can render a [CameraPreview]. The live
/// preview is intrinsic to this feature and there is no value in hiding
/// the controller behind a bespoke type just to draw it — so this one
/// plugin type is allowed to cross into the domain boundary.
abstract class LensRepository {
  /// Stabilised stream of recognised frames (throttled + de-jittered).
  Stream<RecognizedFrame> get frames;

  /// The active camera controller once [start] has succeeded, for the
  /// preview widget. Null before start / after stop.
  CameraController? get previewController;

  /// Initialise the camera + recogniser and begin streaming [frames].
  Future<Either<Failure, Unit>> start();

  /// Stop the image stream and release the camera.
  Future<void> stop();

  /// Take a full-resolution still and OCR it — far more accurate than the
  /// live frames, which are motion-blurred / lower quality. Used on capture.
  Future<Either<Failure, String>> captureText();
}
