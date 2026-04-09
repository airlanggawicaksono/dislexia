import 'package:uuid/uuid.dart';

import '../../../../core/entities/document_entity.dart';

abstract class ScanDatasource {
  Future<DocumentEntity> scanFromCamera();
}

class ScanDatasourceImpl implements ScanDatasource {
  @override
  Future<DocumentEntity> scanFromCamera() async {
    // TODO: Replace with real camera + OCR implementation
    await Future.delayed(const Duration(seconds: 2));

    return DocumentEntity(
      id: const Uuid().v4(),
      text:
          'Dyslexia is a learning difference that primarily affects reading and '
          'language processing. It is not related to intelligence — many people '
          'with dyslexia are highly creative and excel in problem-solving.\n\n'
          'Common signs include difficulty decoding words, slower reading speed, '
          'and challenges with spelling. Letters may appear to move or blur on '
          'the page, making sustained reading tiring.\n\n'
          'Adjustments such as larger fonts, increased spacing between letters '
          'and lines, off-white background colours, and specialised typefaces '
          'like OpenDyslexic can significantly improve readability and reduce '
          'visual stress.',
      sourceName: 'Camera Scan',
    );
  }
}
