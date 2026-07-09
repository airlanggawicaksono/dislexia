import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../configs/injector/injector_conf.dart';
import '../data/datasources/lens_scanner_datasource.dart';
import '../data/repositories/lens_repository_impl.dart';
import '../domain/policies/ocr_stabilizer.dart';
import '../domain/repositories/lens_repository.dart';
import '../domain/usecases/capture_text_usecase.dart';
import '../domain/usecases/lens_preview_usecase.dart';
import '../domain/usecases/start_lens_usecase.dart';
import '../domain/usecases/stop_lens_usecase.dart';
import '../domain/usecases/watch_frames_usecase.dart';
import '../presentation/bloc/lens/lens_bloc.dart';

class LensDependency {
  LensDependency._();

  static void init() {
    // ---- infrastructure -----------------------------------------
    getIt.registerLazySingleton<TextRecognizer>(() => TextRecognizer());
    getIt.registerLazySingleton<OcrStabilizer>(() => OcrStabilizer());

    // ---- data layer ---------------------------------------------
    getIt.registerLazySingleton<LensScannerDatasource>(
      () => LensScannerDatasource(getIt<TextRecognizer>()),
    );
    getIt.registerLazySingleton<LensRepository>(
      () => LensRepositoryImpl(
        getIt<LensScannerDatasource>(),
        getIt<OcrStabilizer>(),
      ),
    );

    // ---- use cases ----------------------------------------------
    getIt.registerLazySingleton(() => StartLensUseCase(getIt<LensRepository>()));
    getIt.registerLazySingleton(() => StopLensUseCase(getIt<LensRepository>()));
    getIt.registerLazySingleton(() => WatchFramesUseCase(getIt<LensRepository>()));
    getIt.registerLazySingleton(() => LensPreviewUseCase(getIt<LensRepository>()));
    getIt.registerLazySingleton(() => CaptureTextUseCase(getIt<LensRepository>()));

    // ---- bloc (factory — fresh per page) ------------------------
    getIt.registerFactory(
      () => LensBloc(
        getIt<StartLensUseCase>(),
        getIt<StopLensUseCase>(),
        getIt<WatchFramesUseCase>(),
        getIt<LensPreviewUseCase>(),
        getIt<CaptureTextUseCase>(),
      ),
    );
  }
}
