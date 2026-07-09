import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/entities/recognized_frame.dart';
import '../../domain/entities/recognized_line.dart';
import 'lens_image_converter.dart';

/// Owns the [CameraController] + ML Kit [TextRecognizer] and turns the live
/// image stream into a throttled [Stream] of [RecognizedFrame]s. Camera +
/// ML Kit plumbing lives here in the data layer; the repository adds
/// stabilisation on top.
class LensScannerDatasource {
  final TextRecognizer _recognizer;

  LensScannerDatasource(this._recognizer);

  CameraController? _controller;
  CameraDescription? _camera;
  final StreamController<RecognizedFrame> _frames =
      StreamController<RecognizedFrame>.broadcast();

  bool _busy = false;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  /// Throttle: at most one OCR pass per interval. Cheap way to keep the
  /// pipeline stable and the device cool.
  static const _minInterval = Duration(milliseconds: 250);

  Stream<RecognizedFrame> get frames => _frames.stream;
  CameraController? get previewController => _controller;

  Future<void> start() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('no_camera', 'No camera available on this device');
    }
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _camera = back;

    final controller = CameraController(
      back,
      // Higher res so dense / small text has enough pixels for ML Kit to
      // resolve. high (~720p) drops crowded text.
      ResolutionPreset.veryHigh,
      enableAudio: false,
      // yuv420 on Android is delivered predictably as 3 planes, which we
      // repack to NV21 ourselves — more reliable across OEMs than asking
      // for nv21 (some devices pad rows or ignore the request).
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    await controller.initialize();
    // Continuous autofocus/exposure keeps live frames as sharp as possible.
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
    } catch (_) {}
    await controller.startImageStream(_onImage);
  }

  /// Pause the stream, take a full-res still, OCR it, then resume. The still
  /// is sharp + full resolution, so its text is much more accurate than the
  /// live frames.
  Future<String> captureStill() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return '';

    final wasStreaming = controller.value.isStreamingImages;
    if (wasStreaming) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }

    String text = '';
    try {
      final file = await controller.takePicture();
      final recognized =
          await _recognizer.processImage(InputImage.fromFilePath(file.path));
      final lines = <String>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          lines.add(line.text);
        }
      }
      text = lines.isEmpty ? recognized.text : lines.join('\n');
    } catch (_) {
      text = '';
    } finally {
      if (wasStreaming &&
          _controller != null &&
          !_controller!.value.isStreamingImages) {
        try {
          await _controller!.startImageStream(_onImage);
        } catch (_) {}
      }
    }
    return text;
  }

  void _onImage(CameraImage image) {
    if (_busy) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessed) < _minInterval) return;
    _busy = true;
    _lastProcessed = now;
    _process(image).whenComplete(() => _busy = false);
  }

  Future<void> _process(CameraImage image) async {
    final controller = _controller;
    final camera = _camera;
    if (controller == null || camera == null || _frames.isClosed) return;

    final input = cameraImageToInputImage(
      image: image,
      controller: controller,
      camera: camera,
    );
    if (input == null) return;

    final RecognizedText recognized;
    try {
      recognized = await _recognizer.processImage(input);
    } catch (_) {
      return; // drop bad frame
    }

    final meta = input.metadata;
    if (meta == null || _frames.isClosed) return;

    final lines = <RecognizedLine>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        lines.add(RecognizedLine(text: line.text, boundingBox: line.boundingBox));
      }
    }

    // Build the full text from the lines we actually extracted rather than
    // recognised.text (which can come back empty even when lines exist).
    final fullText = lines.map((l) => l.text).join('\n');

    _frames.add(RecognizedFrame(
      lines: lines,
      fullText: fullText,
      imageSize: meta.size,
      rotationDegrees: rotationDegrees(meta.rotation),
      isFrontCamera: camera.lensDirection == CameraLensDirection.front,
    ));
  }

  Future<void> stop() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    await controller.dispose();
  }

  Future<void> dispose() async {
    await stop();
    await _recognizer.close();
    await _frames.close();
  }
}
