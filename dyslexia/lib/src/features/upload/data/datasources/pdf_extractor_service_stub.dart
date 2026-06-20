import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'pdf_extractor_service.dart';

/// Mobile/native implementation of [PdfExtractorService] that extracts text
/// from PDFs using syncfusion_flutter_pdf.
///
/// This implementation works on Android and iOS. It loads the PDF from raw
/// bytes and iterates through pages using [PdfTextExtractor].
class PdfExtractorServiceImpl extends PdfExtractorService {
  @override
  Future<String> extractText(
    Uint8List pdfBytes, {
    void Function(int current, int total)? onProgress,
  }) async {
    final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    final buffer = StringBuffer();

    try {
      final totalPages = document.pages.count;
      for (int i = 0; i < totalPages; i++) {
        final pageText = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        buffer.writeln(pageText);
        onProgress?.call(i + 1, totalPages);
      }
    } finally {
      document.dispose();
    }

    return buffer.toString().trim();
  }
}
