import 'package:get_it/get_it.dart';

import '../../features/auth/di/auth_dependency.dart';
import '../../features/display_settings/di/display_settings_dependency.dart';
import '../../features/lens/di/lens_dependency.dart';
import '../../features/reader/di/reader_dependency.dart';
import '../../features/scan_paste/di/scan_dependency.dart';
import '../../features/summarize/di/summarize_dependency.dart';
import '../../features/personalize/di/personalize_dependency.dart';
import '../../features/define/di/define_dependency.dart';
import '../../features/upload/di/upload_dependency.dart';
import '../../core/blocs/theme/theme_bloc.dart';
import '../../routes/app_route_conf.dart';
import '../../core/cache/hive_local_storage.dart';

final getIt = GetIt.I;

void configureDepedencies() {
  AuthDependency.init();
  DisplaySettingsDependency.init();
  UploadDependency.init();
  SummarizeDependency.init();
  DefineDependency.init();
  PersonalizeDependency.init();
  ScanDependency.init();
  LensDependency.init();
  ReaderDependency.init();

  getIt.registerLazySingleton(() => ThemeBloc());
  getIt.registerLazySingleton(() => AppRouteConf());
  getIt.registerLazySingleton(() => HiveLocalStorage());
}
