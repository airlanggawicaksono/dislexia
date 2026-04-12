import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/entities/document_entity.dart';
import 'upload_datasource.dart';

class UploadDatasourceImpl implements UploadDatasource {
  @override
  Future<DocumentEntity> pickAndExtract() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'txt', 'pdf', 'docx'],
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final file = result.files.first;
    final path = file.path;
    if (path == null) throw Exception('Could not access file path');

    final ext = file.extension?.toLowerCase() ?? '';
    final sourceName = file.name;
    final String text;

    switch (ext) {
      case 'txt':
        text = await File(path).readAsString();
      case 'pdf':
        text = await _extractPdfText(path);
      case 'docx':
        text = await _extractDocxText(path);
      default:
        text = await _ocrImage(path);
    }

    return DocumentEntity(
      id: const Uuid().v4(),
      text: text.trim(),
      sourceName: sourceName,
    );
  }

  Future<String> _extractPdfText(String path) async {
    final bytes = await File(path).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final text = PdfTextExtractor(document).extractText();
      return text;
    } finally {
      document.dispose();
    }
  }

  Future<String> _extractDocxText(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final docFile = archive.findFile('word/document.xml');
    if (docFile == null) throw Exception('Invalid or unsupported DOCX file');

    final xml = utf8.decode(docFile.content as List<int>);
    return xml
        .replaceAll(RegExp(r'<w:br[^>]*/?>'), '\n')
        .replaceAll(RegExp(r'<w:p[ >][^>]*>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll("&apos;", "'")
        .replaceAll(RegExp(r' +'), ' ')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
        .trim();
  }

  Future<String> _ocrImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer();
    try {
      final recognized = await recognizer.processImage(inputImage);
      return recognized.text;
    } finally {
      recognizer.close();
    }
  }
}
