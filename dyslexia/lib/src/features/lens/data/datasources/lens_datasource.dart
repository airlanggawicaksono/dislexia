import '../../../../core/entities/document_entity.dart';

abstract class LensDatasource {
  Future<DocumentEntity> captureAndExtract();
}

class LensDatasourceImpl implements LensDatasource {
  // TODO: inject CameraController (live feed)
  // TODO: inject TextRecognizer (google_mlkit_text_recognition)

  @override
  Future<DocumentEntity> captureAndExtract() async {
    // Step 1: Show live CameraPreview, let user tap to capture
    // Step 2: CameraController.takePicture() → XFile
    // Step 3: TextRecognizer.processImage(InputImage.fromFilePath(xfile.path))
    // Step 4: Return DocumentEntity(id: uuid, text: recognized, sourceName: 'Lens')
    throw UnimplementedError('Add camera + google_mlkit_text_recognition');
  }
}
