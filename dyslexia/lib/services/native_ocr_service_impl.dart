// lib/services/native_ocr_service_impl.dart
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_service.dart';

class NativeOcrService implements OcrService {
  @override
  Future<String> recognizeText(Uint8List imageBytes) async {
    try {
      final inputImage = InputImage.fromBytes(bytes: imageBytes);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close(); // Selalu bersihkan resource

      return recognizedText.text.trim();
    } catch (e) {
      print('Error Native OCR: $e');
      throw Exception('Gagal mengekstrak teks: $e');
    }
  }
}

// Fungsi factory untuk platform Native (Mobile/Desktop)
OcrService getOcrService() => NativeOcrService();