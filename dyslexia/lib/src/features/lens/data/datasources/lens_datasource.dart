import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/entities/document_entity.dart';
import '../../../../core/utils/mlkit_utils.dart';
import '../../domain/entities/lens_frame_entity.dart';

abstract class LensDatasource {
  Future<DocumentEntity> captureAndExtract();
  Future<LensFrameEntity> analyzeFrame(AnalysisImage img);
  void dispose();
}

class LensDatasourceImpl implements LensDatasource {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<DocumentEntity> captureAndExtract() async {
    throw UnimplementedError();
  }

  @override
  Future<LensFrameEntity> analyzeFrame(AnalysisImage img) async {
    final result = await _recognizer.processImage(img.toInputImage());

    final isRotated = img.rotation.name.contains('90') ||
        img.rotation.name.contains('270');

    final sorted = [...result.blocks]
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    final text = sorted
        .map((b) => b.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');

    final blocks = sorted
        .map((b) => RecognizedBlockEntity(
              boundingBox: b.boundingBox,
              lineCount: b.lines.length,
            ))
        .toList();

    return LensFrameEntity(
      text: text,
      blocks: blocks,
      imageSize: img.size,
      isRotated: isRotated,
    );
  }

  @override
  void dispose() => _recognizer.close();
}
