import 'package:get_it/get_it.dart';
import '../presentation/bloc/reader/reader_bloc.dart';

class ReaderDependency {
  static void init() {
    GetIt.I.registerLazySingleton(() => ReaderBloc());
  }
}
