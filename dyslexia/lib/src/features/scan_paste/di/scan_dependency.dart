import '../../../configs/injector/injector_conf.dart';
import '../data/datasources/scan_datasource.dart';
import '../data/repositories/scan_repository_impl.dart';
import '../domain/usecases/scan_text_usecase.dart';
import '../presentation/bloc/scan/scan_bloc.dart';

class ScanDependency {
  ScanDependency._();

  static void init() {
    getIt.registerFactory(
      () => ScanBloc(getIt<ScanTextUseCase>()),
    );

    getIt.registerLazySingleton(
      () => ScanTextUseCase(getIt<ScanRepositoryImpl>()),
    );

    getIt.registerLazySingleton(
      () => ScanRepositoryImpl(getIt<ScanDatasourceImpl>()),
    );

    getIt.registerLazySingleton(
      () => ScanDatasourceImpl(),
    );
  }
}
