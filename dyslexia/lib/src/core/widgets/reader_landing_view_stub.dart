import 'dart:typed_data';

/// Stub for non-web platforms — the dropzone registration is a no-op.
void registerPdfDropzone({
  required bool Function() isMounted,
  required void Function(bool) setDragOver,
  required void Function(Uint8List bytes, String fileName) processPdfBytes,
  required void Function(String message) showError,
}) {}
