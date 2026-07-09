import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Device-orientation → degrees, for Android rotation compensation.
const _orientations = <DeviceOrientation, int>{
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

/// Convert a [CameraImage] from the live stream into an ML Kit
/// [InputImage], handling per-platform format + sensor rotation.
///
/// Android: ML Kit needs a single NV21 buffer. Devices don't reliably
/// honour `ImageFormatGroup.nv21` — many still deliver 3-plane YUV_420 —
/// so we normalise *whatever* we get into NV21 here. (The old code only
/// accepted a single nv21 plane and silently dropped everything else,
/// which is why nothing transcribed.)
InputImage? cameraImageToInputImage({
  required CameraImage image,
  required CameraController controller,
  required CameraDescription camera,
}) {
  final rotation = _resolveRotation(controller, camera);
  if (rotation == null) return null;

  final size = Size(image.width.toDouble(), image.height.toDouble());

  if (Platform.isIOS) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format != InputImageFormat.bgra8888 || image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // Android — normalise to NV21. When we repack 3-plane YUV_420 ourselves
  // the buffer is tightly packed (row stride == width). If a device already
  // hands back a single NV21 plane, honour that plane's own row stride.
  final bool alreadyNv21 = image.planes.length == 1;
  final Uint8List nv21 =
      alreadyNv21 ? image.planes.first.bytes : _yuv420ToNv21(image);
  final int bytesPerRow =
      alreadyNv21 ? image.planes.first.bytesPerRow : image.width;

  return InputImage.fromBytes(
    bytes: nv21,
    metadata: InputImageMetadata(
      size: size,
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: bytesPerRow,
    ),
  );
}

InputImageRotation? _resolveRotation(
  CameraController controller,
  CameraDescription camera,
) {
  final sensorOrientation = camera.sensorOrientation;
  if (Platform.isIOS) {
    return InputImageRotationValue.fromRawValue(sensorOrientation);
  }
  var compensation = _orientations[controller.value.deviceOrientation];
  if (compensation == null) return null;
  if (camera.lensDirection == CameraLensDirection.front) {
    compensation = (sensorOrientation + compensation) % 360;
  } else {
    compensation = (sensorOrientation - compensation + 360) % 360;
  }
  return InputImageRotationValue.fromRawValue(compensation);
}

/// Pack a 3-plane YUV_420 [CameraImage] into a contiguous NV21 buffer
/// (Y plane followed by interleaved V/U), respecting each plane's row and
/// pixel strides.
Uint8List _yuv420ToNv21(CameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final int ySize = width * height;
  final int uvSize = (width ~/ 2) * (height ~/ 2);
  final out = Uint8List(ySize + uvSize * 2);

  final yP = image.planes[0];
  final uP = image.planes[1];
  final vP = image.planes[2];

  // Y plane
  int outIndex = 0;
  for (int row = 0; row < height; row++) {
    final int rowStart = row * yP.bytesPerRow;
    for (int col = 0; col < width; col++) {
      out[outIndex++] = yP.bytes[rowStart + col];
    }
  }

  // Interleaved V/U (NV21 = ...VUVU)
  final int uvRowStride = uP.bytesPerRow;
  final int uvPixelStride = uP.bytesPerPixel ?? 1;
  for (int row = 0; row < height ~/ 2; row++) {
    for (int col = 0; col < width ~/ 2; col++) {
      final int uvIndex = row * uvRowStride + col * uvPixelStride;
      out[outIndex++] = vP.bytes[uvIndex];
      out[outIndex++] = uP.bytes[uvIndex];
    }
  }
  return out;
}

int rotationDegrees(InputImageRotation rotation) {
  switch (rotation) {
    case InputImageRotation.rotation0deg:
      return 0;
    case InputImageRotation.rotation90deg:
      return 90;
    case InputImageRotation.rotation180deg:
      return 180;
    case InputImageRotation.rotation270deg:
      return 270;
  }
}
