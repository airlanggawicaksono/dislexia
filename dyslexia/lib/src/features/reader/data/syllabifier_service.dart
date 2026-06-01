// lib/src/features/reader/data/syllabifier_service.dart
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// A service to syllabify text using a background web worker.
/// This is web-only.
class SyllabifierService {
  Future<String> syllabify(String text) async {
    if (!kIsWeb) {
      // Fallback for non-web platforms if needed, or throw unimplemented
      return text; // For now, return original text on non-web
    }

    final completer = Completer<String>();
    final worker = html.Worker('js/syllabifier-worker.js');

    // Listen for messages from the worker.
    worker.onMessage.listen((event) {
      final data = event.data as Map<dynamic, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'result':
          final syllabifiedText = data['text'] as String;
          completer.complete(syllabifiedText);
          worker.terminate(); // Clean up the worker when done.
          break;
        case 'error':
          final message = data['message'] as String;
          completer.completeError(Exception(message));
          worker.terminate(); // Clean up on error.
          break;
      }
    });

    // Listen for any errors from the worker itself.
    worker.onError.listen((event) {
      String errorMessage =
          'An unknown worker error occurred during syllabification.';
      if (event is html.ErrorEvent) {
        errorMessage =
            'Worker error: ${event.message} at ${event.filename}:${event.lineno}';
      }
      completer.completeError(Exception(errorMessage));
      worker.terminate();
    });

    // Send the text to the worker to start syllabification.
    worker.postMessage(text);

    return completer.future;
  }
}
