import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Extension to convert camerawesome [AnalysisImage] → ML Kit [InputImage].
/// Handles NV21 (Android) and BGRA8888 (iOS) formats.
extension AnalysisImageMLKit on AnalysisImage {
  InputImage toInputImage() {
    return when(
      nv21: (image) => InputImage.fromBytes(
        bytes: image.bytes,
        metadata: InputImageMetadata(
          rotation: _rotation,
          format: InputImageFormat.nv21,
          size: image.size,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      ),
      bgra8888: (image) => InputImage.fromBytes(
        bytes: image.bytes,
        metadata: InputImageMetadata(
          size: size,
          rotation: _rotation,
          format: _format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      ),
    )!;
  }

  InputImageRotation get _rotation =>
      InputImageRotation.values.byName(rotation.name);

  InputImageFormat get _format {
    switch (format) {
      case InputAnalysisImageFormat.bgra8888:
        return InputImageFormat.bgra8888;
      case InputAnalysisImageFormat.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }
}
