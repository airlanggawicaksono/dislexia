import '../../../configs/injector/injector_conf.dart' show getIt;
import '../../../core/api/api_helper.dart';
import '../data/datasources/screening_remote_datasource.dart';
import '../data/repositories/screening_repository_impl.dart';
import '../domain/repositories/screening_repository.dart';
import '../domain/usecases/screening_usecase.dart';
import '../presentation/bloc/screening_bloc.dart';

class ScreeningDependency {
  ScreeningDependency._();

  static void init() {
    getIt.registerLazySingleton<ScreeningRemoteDatasource>(
      () => ScreeningRemoteDatasourceImpl(getIt<ApiHelper>()),
    );
    getIt.registerLazySingleton<ScreeningRepository>(
      () => ScreeningRepositoryImpl(getIt<ScreeningRemoteDatasource>()),
    );
    getIt.registerLazySingleton(
      () => ScreeningUseCase(getIt<ScreeningRepository>()),
    );
    getIt.registerLazySingleton(
      () => ScreeningBloc(screening: getIt<ScreeningUseCase>()),
    );
  }
}
