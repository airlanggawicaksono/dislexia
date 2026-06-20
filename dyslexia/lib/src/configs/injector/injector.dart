import 'package:get_it/get_it.dart';

import '../../features/auth/di/auth_dependency.dart';
import '../../features/display_settings/di/display_settings_dependency.dart';
import '../../features/lens/di/lens_dependency.dart';
import '../../features/reader/di/reader_dependency.dart';
import '../../features/scan_paste/di/scan_dependency.dart';
import '../../features/sidebar/di/sidebar_dependency.dart';
import '../../features/summarize/di/summarize_dependency.dart';
import '../../features/professionalize/di/professionalize_dependency.dart';
import '../../features/define/di/define_dependency.dart';
import '../../features/screening/di/screening_dependency.dart';
import '../../features/upload/di/upload_dependency.dart';
import '../../core/blocs/theme/theme_bloc.dart';
import '../../routes/app_route_conf.dart';
import '../../core/cache/local_storage.dart';
import '../../core/cache/shared_prefs_storage.dart';

final getIt = GetIt.I;

void configureDepedencies() {
  AuthDependency.init();
  DisplaySettingsDependency.init();
  UploadDependency.init();
  SummarizeDependency.init();
  DefineDependency.init();
  ProfessionalizeDependency.init();
  ScreeningDependency.init();
  ScanDependency.init();
  SidebarDependency.init();
  LensDependency.init();
  ReaderDependency.init();

  getIt.registerLazySingleton(() => ThemeBloc());
  getIt.registerLazySingleton(() => AppRouteConf());
  getIt.registerLazySingleton<LocalStorage>(() => SharedPrefsLocalStorage());
}
