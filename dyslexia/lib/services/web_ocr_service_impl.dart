// lib/src/services/web_ocr_service_impl.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_util' as js_util;
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'ocr_service.dart';

class WebOcrService implements OcrService {
  @override
  Future<String> recognizeText(Uint8List imageBytes) async {
    try {
      // ✅ PERBAIKAN: Gunakan 'Tesseract' dengan huruf 'T' besar (case-sensitive di JavaScript)
      final tesseract = js_util.getProperty(web.window, 'Tesseract');
      
      if (tesseract == null) {
        throw Exception('Tesseract.js belum dimuat. Periksa web/index.html Anda dan lakukan Hard Refresh (Ctrl+F5).');
      }

      final jsUint8Array = imageBytes.toJS;
      final blobParts = [jsUint8Array].toJS;
      final blob = web.Blob(blobParts);
      
      final fileParts = [blob].toJS;
      final file = web.File(fileParts, 'image.png');

      final options = js_util.jsify({
        'logger': (dynamic m) {
          if (m['status'] == 'recognizing text') {
            print('OCR Progress: ${(m['progress'] * 100).toStringAsFixed(2)}%');
          }
        }
      });

      final jsPromise = js_util.callMethod(tesseract, 'recognize', [file, 'ind+eng', options]);
      final result = await js_util.promiseToFuture(jsPromise);
      
      final data = js_util.getProperty(result, 'data');
      final text = js_util.getProperty(data, 'text') as String;

      return text.trim();
    } catch (e) {
      print('Error Web OCR: $e');
      throw Exception('Gagal mengekstrak teks: $e');
    }
  }
}

// ✅ WAJIB ADA DI PALING BAWAH FILE INI:
// Fungsi ini yang akan dipanggil oleh feature_page.dart melalui locator
OcrService getOcrService() => WebOcrService();