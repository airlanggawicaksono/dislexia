import '../../../../core/entities/document_entity.dart';

abstract class UploadDatasource {
  Future<DocumentEntity> pickAndExtract();
}
