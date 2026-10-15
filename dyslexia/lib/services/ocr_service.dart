import 'dart:typed_data';

abstract class OcrService {
  Future<String> recognizeText(Uint8List imageBytes);
}