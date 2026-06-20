// Conditional import: on web (where dart:js_interop is available), use the
// web implementation; otherwise fall back to the stub (mobile/native).
export 'pdf_extractor_service_stub.dart'
  if (dart.library.js_interop) 'pdf_extractor_service_web.dart';
