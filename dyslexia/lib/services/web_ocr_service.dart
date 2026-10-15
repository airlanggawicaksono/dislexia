// lib/services/web_ocr_service_impl.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'ocr_service.dart';

class WebOcrServiceImpl implements OcrService {
  @override
  Future<String> recognizeText(Uint8List imageBytes) async {
    try {
      // 1. Ambil instance Tesseract dari window browser
      final tesseract = js_util.getProperty(web.window, 'tesseract');
      
      if (tesseract == null) {
        throw Exception(
          'Tesseract tidak ditemukan. Pastikan script Tesseract.js sudah dimuat di web/index.html',
        );
      }

      // 2. Konversi Uint8List menjadi web.File agar bisa dibaca Tesseract.js
      final blob = web.Blob([imageBytes]);
      final file = web.File([blob], 'image.png');

      // 3. Gunakan js_util.jsify untuk mengonversi Map Dart ke JavaScript Object
      final options = js_util.jsify({
        'logger': (dynamic m) {
          if (m['status'] == 'recognizing text') {
            print('OCR Progress: ${(m['progress'] * 100).toStringAsFixed(2)}%');
          }
        }
      });

      // 4. Panggil method recognize (ind+eng untuk Bahasa Indonesia & Inggris)
      final jsPromise = js_util.callMethod(tesseract, 'recognize', [file, 'ind+eng', options]);

      // 5. Konversi JS Promise ke Dart Future
      final result = await js_util.promiseToFuture(jsPromise);

      // 6. Ekstrak teks
      final data = js_util.getProperty(result, 'data');
      final text = js_util.getProperty(data, 'text') as String;

      return text.trim();
    } catch (e) {
      print('Error saat Web OCR: $e');
      return '';
    }
  }
}