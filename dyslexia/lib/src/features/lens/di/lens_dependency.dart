import '../../../configs/injector/injector_conf.dart';
import '../data/datasources/lens_datasource.dart';
import '../data/repositories/lens_repository_impl.dart';
import '../domain/usecases/capture_text_usecase.dart';
import '../presentation/bloc/lens/lens_bloc.dart';

class LensDependency {
  LensDependency._();

  static void init() {
    getIt.registerFactory(
      () => LensBloc(getIt<CaptureTextUseCase>()),
    );

    getIt.registerLazySingleton(
      () => CaptureTextUseCase(getIt<LensRepositoryImpl>()),
    );

    getIt.registerLazySingleton(
      () => LensRepositoryImpl(getIt<LensDatasourceImpl>()),
    );

    getIt.registerLazySingleton(
      () => LensDatasourceImpl(),
    );
  }
}
