import 'package:get_it/get_it.dart';
import '../data/datasources/local_syllabifier_datasource.dart';
import '../data/repositories/reader_repository_impl.dart';
import '../domain/repositories/reader_repository.dart';
import '../presentation/bloc/reader/reader_bloc.dart';

class ReaderDependency {
  static void init() {
    GetIt.I.registerLazySingleton<LocalSyllabifierDatasource>(
      () => LocalSyllabifierDatasource(),
    );
    GetIt.I.registerLazySingleton<ReaderRepository>(
      () => ReaderRepositoryImpl(
        GetIt.I<LocalSyllabifierDatasource>(),
      ),
    );
    GetIt.I.registerLazySingleton(
      () => ReaderBloc(GetIt.I<ReaderRepository>()),
    );
  }
}
