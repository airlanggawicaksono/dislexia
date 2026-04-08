import '../../../configs/injector/injector_conf.dart';
import '../presentation/bloc/display_settings/display_settings_bloc.dart';

class DisplaySettingsDependency {
  DisplaySettingsDependency._();

  static void init() {
    getIt.registerLazySingleton(
      () => DisplaySettingsBloc(),
    );
  }
}
