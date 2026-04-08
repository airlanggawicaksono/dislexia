import '../../../../core/entities/document_entity.dart';

abstract class UploadDatasource {
  Future<DocumentEntity> pickAndExtract();
}

class UploadDatasourceImpl implements UploadDatasource {
  // TODO: inject FilePicker once `file_picker` package is added
  // TODO: inject TextRecognizer once `google_mlkit_text_recognition` is added

  @override
  Future<DocumentEntity> pickAndExtract() async {
    // Step 1: FilePicker.platform.pickFiles(type: FileType.custom,
    //           allowedExtensions: ['txt', 'pdf', 'jpg', 'png', 'jpeg'])
    // Step 2: Read bytes / path from picked file
    // Step 3: For images → run OCR via google_mlkit_text_recognition
    //         For .txt  → read as utf-8 string
    //         For .pdf  → use a pdf reader package
    // Step 4: Return DocumentEntity(id: uuid, text: extracted, sourceName: file name)
    throw UnimplementedError('Add file_picker + google_mlkit_text_recognition');
  }
}
