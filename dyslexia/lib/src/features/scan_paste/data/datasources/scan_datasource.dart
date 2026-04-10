import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/entities/document_entity.dart';

abstract class ScanDatasource {
  Future<DocumentEntity> scanFromCamera(String imagePath);
}

class ScanDatasourceImpl implements ScanDatasource {
  @override
  Future<DocumentEntity> scanFromCamera(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);

      return DocumentEntity(
        id: const Uuid().v4(),
        text: recognizedText.text,
        sourceName: 'Camera Scan',
      );
    } finally {
      textRecognizer.close();
    }
  }
}
