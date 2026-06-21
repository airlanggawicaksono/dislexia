import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

/// Web-only implementation: registers an HTML-based drop zone platform view
/// that handles native browser drag-and-drop and click-to-browse for PDF files.
void registerPdfDropzone({
  required bool Function() isMounted,
  required void Function(bool) setDragOver,
  required void Function(Uint8List bytes, String fileName) processPdfBytes,
  required void Function(String message) showError,
}) {
  ui_web.platformViewRegistry.registerViewFactory(
    'pdf-dropzone-view',
    (int viewId) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.style
        ..width = '100%'
        ..height = '100%'
        ..cursor = 'pointer'
        ..borderRadius = '16px';

      // click — open file picker via hidden <input type="file">
      div.addEventListener('click', (web.Event event) {
        final input =
            web.document.createElement('input') as web.HTMLInputElement;
        input.type = 'file';
        input.accept = '.pdf';
        input.style.display = 'none';
        web.document.body?.appendChild(input);
        input.addEventListener('change', (web.Event _) {
          final files = input.files;
          if (files == null || files.length == 0) {
            input.remove();
            return;
          }
          final file = files.item(0);
          if (file == null) {
            input.remove();
            return;
          }
          final reader = web.FileReader();
          reader.addEventListener('load', (web.Event _) {
            final buffer = reader.result! as JSArrayBuffer;
            final bytes = buffer.toDart.asUint8List();
            processPdfBytes(bytes, file.name);
          }.toJS);
          reader.readAsArrayBuffer(file);
        }.toJS);
        input.addEventListener('cancel', (web.Event _) {
          input.remove();
        }.toJS);
        input.click();
      }.toJS);

      // dragover — must call preventDefault to allow drop
      div.addEventListener('dragover', (web.Event event) {
        event.preventDefault();
        if (isMounted()) setDragOver(true);
      }.toJS);

      // dragleave
      div.addEventListener('dragleave', (web.Event event) {
        if (isMounted()) setDragOver(false);
      }.toJS);

      // drop
      div.addEventListener('drop', (web.Event event) {
        event.preventDefault();
        if (!isMounted()) return;
        setDragOver(false);

        final dragEvent = event as web.DragEvent;
        final files = dragEvent.dataTransfer?.files;
        if (files == null || files.length == 0) return;

        final file = files.item(0);
        if (file == null) return;
        if (!file.name.toLowerCase().endsWith('.pdf')) {
          if (isMounted()) {
            showError('Only PDF files are supported');
          }
          return;
        }

        // Read the file as ArrayBuffer using FileReader
        final reader = web.FileReader();
        reader.addEventListener('load', (web.Event _) {
          final buffer = reader.result! as JSArrayBuffer;
          final bytes = buffer.toDart.asUint8List();
          processPdfBytes(bytes, file.name);
        }.toJS);
        reader.readAsArrayBuffer(file);
      }.toJS);

      return div;
    },
  );
}
