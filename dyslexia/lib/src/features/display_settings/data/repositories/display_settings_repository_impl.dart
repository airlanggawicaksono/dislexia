import '../../domain/entities/display_settings_entity.dart';
import '../../domain/repositories/display_settings_repository.dart';
import '../datasources/display_settings_local_datasource.dart';
import '../models/display_settings_model.dart';

class DisplaySettingsRepositoryImpl implements DisplaySettingsRepository {
  final DisplaySettingsLocalDatasource _datasource;

  const DisplaySettingsRepositoryImpl(this._datasource);

  @override
  Future<DisplaySettingsEntity> load() async {
    final data = await _datasource.load();
    if (data.isEmpty) return DisplaySettingsModel.defaults();
    return DisplaySettingsModel.fromMap(data);
  }

  @override
  Future<void> save(DisplaySettingsEntity settings) async {
    final model = settings is DisplaySettingsModel
        ? settings
        : DisplaySettingsModel(
            fontSize: settings.fontSize,
            lineSpacing: settings.lineSpacing,
            letterSpacing: settings.letterSpacing,
            wordSpacing: settings.wordSpacing,
            font: settings.font,
            colorTheme: settings.colorTheme,
            preset: settings.preset,
            rulerEnabled: settings.rulerEnabled,
            syllablesEnabled: settings.syllablesEnabled,
          );
    await _datasource.save(model.toMap());
  }
}
