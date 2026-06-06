import '../../../configs/injector/injector_conf.dart' show getIt;
import '../../../core/api/api_helper.dart';
import '../data/datasources/define_remote_datasource.dart';
import '../data/repositories/define_repository_impl.dart';
import '../domain/repositories/define_repository.dart';
import '../domain/usecases/define_usecase.dart';
import '../presentation/bloc/define_bloc.dart';

class DefineDependency {
  DefineDependency._();

  static void init() {
    getIt.registerLazySingleton<DefineRemoteDatasource>(
      () => DefineRemoteDatasourceImpl(getIt<ApiHelper>()),
    );
    getIt.registerLazySingleton<DefineRepository>(
      () => DefineRepositoryImpl(getIt<DefineRemoteDatasource>()),
    );
    getIt.registerLazySingleton(
      () => DefineUseCase(getIt<DefineRepository>()),
    );
    getIt.registerFactory(
      () => DefineBloc(define: getIt<DefineUseCase>()),
    );
  }
}
