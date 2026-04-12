import '../../../configs/injector/injector_conf.dart';
import '../data/datasources/upload_datasource_impl.dart';
import '../data/repositories/upload_repository_impl.dart';
import '../domain/usecases/pick_and_extract_usecase.dart';
import '../presentation/bloc/upload/upload_bloc.dart';

class UploadDependency {
  UploadDependency._();

  static void init() {
    getIt.registerFactory(
      () => UploadBloc(getIt<PickAndExtractUseCase>()),
    );

    getIt.registerLazySingleton(
      () => PickAndExtractUseCase(getIt<UploadRepositoryImpl>()),
    );

    getIt.registerLazySingleton(
      () => UploadRepositoryImpl(getIt<UploadDatasourceImpl>()),
    );

    getIt.registerLazySingleton(
      () => UploadDatasourceImpl(),
    );
  }
}
