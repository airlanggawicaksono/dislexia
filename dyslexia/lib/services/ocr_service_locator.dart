// lib/services/ocr_service_locator.dart (atau lib/src/services/...)
// File ini memilih implementasi OCR yang tepat berdasarkan platform

export 'ocr_service_stub.dart'
    if (dart.library.html) 'web_ocr_service_impl.dart'
    if (dart.library.io) 'native_ocr_service_impl.dart';