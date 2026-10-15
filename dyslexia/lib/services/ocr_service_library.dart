// lib/services/ocr_service_factory.dart
// Secara default gunakan Native, TAPI jika platformnya Web (punya dart.library.js_util), gunakan Web.
export 'native_ocr_service_impl.dart'
    if (dart.library.js_util) 'web_ocr_service_impl.dart';