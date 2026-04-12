import 'dart:ui';

import '../../../../core/entities/document_entity.dart';
import '../../domain/entities/lens_frame_entity.dart';
import '../../domain/entities/lens_scan_payload_entity.dart';

abstract class LensDatasource {
  Future<DocumentEntity> captureAndExtract();
  Future<LensFrameEntity> analyzeFrame(LensScanPayloadEntity payload);
  void dispose();
}

class LensDatasourceImpl implements LensDatasource {
  @override
  Future<DocumentEntity> captureAndExtract() async {
    throw UnimplementedError();
  }

  @override
  Future<LensFrameEntity> analyzeFrame(LensScanPayloadEntity payload) async {
    final text = payload.scannedText.trim();
    final blocks = payload.rawElements
        .map(_mapRawElementToBlock)
        .whereType<RecognizedBlockEntity>()
        .toList();

    return LensFrameEntity(
      text: text,
      blocks: blocks,
      imageSize: Size.zero,
      isRotated: false,
    );
  }

  @override
  void dispose() {}

  RecognizedBlockEntity? _mapRawElementToBlock(dynamic raw) {
    try {
      final dynamic element = raw;
      final Rect? box =
          element.boundingBox is Rect ? element.boundingBox : null;
      final int lineCount = _resolveLineCount(element);
      return RecognizedBlockEntity(
        boundingBox: box,
        lineCount: lineCount,
      );
    } catch (_) {
      return null;
    }
  }

  int _resolveLineCount(dynamic element) {
    try {
      final lines = element.lines;
      if (lines is List) return lines.length;
    } catch (_) {}

    try {
      final text = element.text?.toString() ?? '';
      if (text.isEmpty) return 0;
      return '\n'.allMatches(text).length + 1;
    } catch (_) {
      return 0;
    }
  }
}
