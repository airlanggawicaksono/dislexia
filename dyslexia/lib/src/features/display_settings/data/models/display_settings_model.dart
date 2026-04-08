import '../../domain/entities/display_settings_entity.dart';

class DisplaySettingsModel extends DisplaySettingsEntity {
  const DisplaySettingsModel({
    required super.fontSize,
    required super.font,
    required super.colorTheme,
    required super.preset,
  });

  factory DisplaySettingsModel.defaults() => const DisplaySettingsModel(
        fontSize: 16.0,
        font: DyslexiaFont.openDyslexic,
        colorTheme: AppColorTheme.light,
        preset: DisplayPreset.defaultPreset,
      );

  Map<String, dynamic> toMap() => {
        'fontSize': fontSize,
        'font': font.index,
        'colorTheme': colorTheme.index,
        'preset': preset.index,
      };

  factory DisplaySettingsModel.fromMap(Map<String, dynamic> map) =>
      DisplaySettingsModel(
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 16.0,
        font: DyslexiaFont.values[map['font'] as int? ?? 0],
        colorTheme: AppColorTheme.values[map['colorTheme'] as int? ?? 0],
        preset: DisplayPreset.values[map['preset'] as int? ?? 0],
      );

  DisplaySettingsModel copyWith({
    double? fontSize,
    DyslexiaFont? font,
    AppColorTheme? colorTheme,
    DisplayPreset? preset,
  }) =>
      DisplaySettingsModel(
        fontSize: fontSize ?? this.fontSize,
        font: font ?? this.font,
        colorTheme: colorTheme ?? this.colorTheme,
        preset: preset ?? this.preset,
      );
}
