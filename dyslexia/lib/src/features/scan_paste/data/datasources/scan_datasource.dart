import '../../../../core/entities/document_entity.dart';

abstract class ScanDatasource {
  Future<DocumentEntity> scanFromCamera();
}

class ScanDatasourceImpl implements ScanDatasource {
  // TODO: inject ImagePicker or CameraController
  // TODO: inject TextRecognizer (google_mlkit_text_recognition)

  @override
  Future<DocumentEntity> scanFromCamera() async {
    // Step 1: Launch camera via ImagePicker.pickImage(source: ImageSource.camera)
    // Step 2: Pass image file to TextRecognizer.processImage(InputImage.fromFile(...))
    // Step 3: Collect RecognizedText.text
    // Step 4: Return DocumentEntity(id: uuid, text: recognized, sourceName: 'Camera Scan')
    throw UnimplementedError('Add camera + google_mlkit_text_recognition');
  }
}
