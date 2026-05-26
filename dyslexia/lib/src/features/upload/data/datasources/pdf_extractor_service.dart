// lib/src/features/upload/data/datasources/pdf_extractor_service.dart
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

/// Extracts text from a PDF using pdf.js (loaded via <script> in index.html).
/// Uses dart:js_interop to call pdf.js APIs directly.
/// pdf.js handles heavy parsing internally via its own Worker.
class PdfExtractorService {
  Future<String> extractText(
    Uint8List pdfBytes, {
    void Function(int current, int total)? onProgress,
  }) async {
    if (!kIsWeb) {
      throw UnimplementedError(
          'PDF extraction with pdf.js is only supported on web.');
    }

    // Access the global pdfjsLib object.
    final pdfjsLib = globalContext['pdfjsLib'] as JSObject?;
    if (pdfjsLib == null) {
      throw Exception(
        'pdf.js library not found. '
        'Ensure <script src="js/pdfjs/pdf.min.js"></script> is in web/index.html.',
      );
    }

    // Set internal worker path.
    final workerOptions = pdfjsLib['GlobalWorkerOptions'] as JSObject;
    workerOptions['workerSrc'] = './js/pdfjs/pdf.worker.min.js'.toJS;

    // Build config: { data: new Uint8Array(pdfBytes) }
    final uint8array = pdfBytes.toJS;
    final config = {'data': uint8array}.jsify() as JSObject;

    // Call pdfjsLib.getDocument(config).
    final getDocument = pdfjsLib['getDocument'] as JSFunction;
    final loadingTask =
        getDocument.callAsFunction(pdfjsLib, config) as JSObject;

    // Await the promise.
    final pdf = await (loadingTask['promise'] as JSPromise).toDart;
    final pdfDoc = pdf as JSObject;

    final totalPages = (pdfDoc['numPages'] as JSNumber).toDartInt;
    final buffer = StringBuffer();

    for (int i = 1; i <= totalPages; i++) {
      // pdfDoc.getPage(i)
      final getPage = pdfDoc['getPage'] as JSFunction;
      final page = await (getPage.callAsFunction(pdfDoc, i.toJS) as JSPromise)
          .toDart as JSObject;

      // page.getTextContent()
      final getTextContent = page['getTextContent'] as JSFunction;
      final textContent =
          await (getTextContent.callAsFunction(page) as JSPromise).toDart
              as JSObject;

      // Extract strings from items array.
      final items = textContent['items'] as JSArray;
      final pageText = items.toDart
          .map((e) => ((e as JSObject)['str'] as JSString).toDart)
          .join(' ');
      buffer.writeln(pageText);

      onProgress?.call(i, totalPages);
    }

    return buffer.toString().trim();
  }
}
