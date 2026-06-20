import '../entities/display_settings_entity.dart';

abstract class DisplaySettingsRepository {
  Future<DisplaySettingsEntity> load();
  Future<void> save(DisplaySettingsEntity settings);
}
