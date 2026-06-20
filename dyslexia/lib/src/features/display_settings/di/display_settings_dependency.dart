import '../../../configs/injector/injector_conf.dart';
import '../../../core/cache/local_storage.dart';
import '../data/datasources/display_settings_local_datasource.dart';
import '../data/repositories/display_settings_repository_impl.dart';
import '../domain/repositories/display_settings_repository.dart';
import '../presentation/bloc/display_settings/display_settings_bloc.dart';

class DisplaySettingsDependency {
  DisplaySettingsDependency._();

  static void init() {
    // Lazy singletons for the data layer — LocalStorage hasn't been
    // registered yet when init() runs, so defer resolution.
    getIt.registerLazySingleton<DisplaySettingsLocalDatasource>(
      () => DisplaySettingsLocalDatasource(getIt<LocalStorage>()),
    );
    getIt.registerLazySingleton<DisplaySettingsRepository>(
      () => DisplaySettingsRepositoryImpl(
        getIt<DisplaySettingsLocalDatasource>(),
      ),
    );
    // Factory: each BlocProvider gets its own bloc instance so that
    // dispose-and-recreate cycles (auth gate, hot reload) don't leave
    // a closed singleton behind. The datasource + repository are
    // lazy singletons so storage is shared.
    getIt.registerFactory(
      () => DisplaySettingsBloc(getIt<DisplaySettingsRepository>()),
    );
  }
}
