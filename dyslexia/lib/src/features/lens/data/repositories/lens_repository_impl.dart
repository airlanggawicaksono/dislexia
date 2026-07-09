import 'package:camera/camera.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/recognized_frame.dart';
import '../../domain/policies/ocr_stabilizer.dart';
import '../../domain/repositories/lens_repository.dart';
import '../datasources/lens_scanner_datasource.dart';

class LensRepositoryImpl implements LensRepository {
  final LensScannerDatasource _scanner;
  final OcrStabilizer _stabilizer;

  LensRepositoryImpl(this._scanner, this._stabilizer);

  @override
  Stream<RecognizedFrame> get frames => _scanner.frames.map(
        (f) => f.copyWith(fullText: _stabilizer.stabilize(f.fullText)),
      );

  @override
  CameraController? get previewController => _scanner.previewController;

  @override
  Future<Either<Failure, Unit>> start() async {
    try {
      _stabilizer.reset();
      await _scanner.start();
      return right(unit);
    } on CameraException catch (e) {
      return left(CameraFailure(e.description ?? e.code));
    } catch (e) {
      return left(CameraFailure(e.toString()));
    }
  }

  @override
  Future<void> stop() => _scanner.stop();

  @override
  Future<Either<Failure, String>> captureText() async {
    try {
      final text = await _scanner.captureStill();
      if (text.trim().isEmpty) return left(const OcrFailure());
      return right(text);
    } catch (e) {
      return left(CameraFailure(e.toString()));
    }
  }
}
