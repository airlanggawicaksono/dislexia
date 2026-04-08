import 'package:get_it/get_it.dart';

import 'injector.dart';

final getIt = GetIt.I;

void configureDepedencies() {
  DisplaySettingsDependency.init();
  UploadDependency.init();
  ScanDependency.init();
  LensDependency.init();

  getIt.registerLazySingleton(() => ThemeBloc());
  getIt.registerLazySingleton(() => TranslateBloc());
  getIt.registerLazySingleton(() => AppRouteConf());
  getIt.registerLazySingleton(() => HiveLocalStorage());
}
