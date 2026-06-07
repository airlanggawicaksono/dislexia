import '../../../configs/injector/injector_conf.dart' show getIt;
import '../../../core/api/api_helper.dart';
import '../data/datasources/professionalize_remote_datasource.dart';
import '../data/repositories/professionalize_repository_impl.dart';
import '../domain/repositories/professionalize_repository.dart';
import '../domain/usecases/professionalize_usecase.dart';
import '../presentation/bloc/professionalize_bloc.dart';

class ProfessionalizeDependency {
  ProfessionalizeDependency._();

  static void init() {
    getIt.registerLazySingleton<ProfessionalizeRemoteDatasource>(
      () => ProfessionalizeRemoteDatasourceImpl(getIt<ApiHelper>()),
    );
    getIt.registerLazySingleton<ProfessionalizeRepository>(
      () => ProfessionalizeRepositoryImpl(getIt<ProfessionalizeRemoteDatasource>()),
    );
    getIt.registerLazySingleton(
      () => ProfessionalizeUseCase(getIt<ProfessionalizeRepository>()),
    );
    getIt.registerLazySingleton(
      () => ProfessionalizeBloc(professionalize: getIt<ProfessionalizeUseCase>()),
    );
  }
}
