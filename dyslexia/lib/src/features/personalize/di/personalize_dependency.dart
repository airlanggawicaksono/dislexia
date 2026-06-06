import '../../../configs/injector/injector_conf.dart' show getIt;
import '../../../core/api/api_helper.dart';
import '../data/datasources/personalize_remote_datasource.dart';
import '../data/repositories/personalize_repository_impl.dart';
import '../domain/repositories/personalize_repository.dart';
import '../domain/usecases/personalize_usecase.dart';
import '../presentation/bloc/personalize_bloc.dart';

class PersonalizeDependency {
  PersonalizeDependency._();

  static void init() {
    getIt.registerLazySingleton<PersonalizeRemoteDatasource>(
      () => PersonalizeRemoteDatasourceImpl(getIt<ApiHelper>()),
    );
    getIt.registerLazySingleton<PersonalizeRepository>(
      () => PersonalizeRepositoryImpl(getIt<PersonalizeRemoteDatasource>()),
    );
    getIt.registerLazySingleton(
      () => PersonalizeUseCase(getIt<PersonalizeRepository>()),
    );
    getIt.registerFactory(
      () => PersonalizeBloc(personalize: getIt<PersonalizeUseCase>()),
    );
  }
}
