import 'dart:typed_data';

/// Extracts text from a PDF file.
///
/// Platform-specific implementations are automatically selected via
/// conditional imports in [pdf_extractor_service_impl.dart].
abstract class PdfExtractorService {
  Future<String> extractText(
    Uint8List pdfBytes, {
    void Function(int current, int total)? onProgress,
  });
}
