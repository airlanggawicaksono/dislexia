import '../../../configs/injector/injector_conf.dart' show getIt;
import '../../../core/api/api_helper.dart';
import '../data/datasources/summarize_remote_datasource.dart';
import '../data/repositories/summarize_repository_impl.dart';
import '../domain/repositories/summarize_repository.dart';
import '../domain/usecases/summarize_usecase.dart';
import '../presentation/bloc/summarize_bloc.dart';

class SummarizeDependency {
  SummarizeDependency._();

  static void init() {
    getIt.registerLazySingleton<SummarizeRemoteDatasource>(
      () => SummarizeRemoteDatasourceImpl(getIt<ApiHelper>()),
    );
    getIt.registerLazySingleton<SummarizeRepository>(
      () => SummarizeRepositoryImpl(getIt<SummarizeRemoteDatasource>()),
    );
    getIt.registerLazySingleton(
      () => SummarizeUseCase(getIt<SummarizeRepository>()),
    );
    getIt.registerFactory(
      () => SummarizeBloc(summarize: getIt<SummarizeUseCase>()),
    );
  }
}
