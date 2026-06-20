import '../../../configs/injector/injector_conf.dart';
import '../presentation/bloc/sidebar/sidebar_bloc.dart';

class SidebarDependency {
  SidebarDependency._();

  static void init() {
    getIt.registerLazySingleton(
      () => SidebarBloc(),
    );
  }
}
