import '../../domain/entities/display_settings_entity.dart';

class DisplaySettingsModel extends DisplaySettingsEntity {
  const DisplaySettingsModel({
    required super.fontSize,
    required super.lineSpacing,
    required super.letterSpacing,
    required super.wordSpacing,
    required super.font,
    required super.colorTheme,
    required super.preset,
  });

  factory DisplaySettingsModel.defaults() => const DisplaySettingsModel(
        fontSize: 18.0,
        lineSpacing: 1.5,
        letterSpacing: 0.5,
        wordSpacing: 4.0,
        font: DyslexiaFont.openDyslexic,
        colorTheme: AppColorTheme.cream,
        preset: DisplayPreset.defaultPreset,
      );

  Map<String, dynamic> toMap() => {
        'fontSize': fontSize,
        'lineSpacing': lineSpacing,
        'letterSpacing': letterSpacing,
        'wordSpacing': wordSpacing,
        'font': font.index,
        'colorTheme': colorTheme.index,
        'preset': preset.index,
      };

  factory DisplaySettingsModel.fromMap(Map<String, dynamic> map) =>
      DisplaySettingsModel(
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0,
        lineSpacing: (map['lineSpacing'] as num?)?.toDouble() ?? 1.5,
        letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 0.5,
        wordSpacing: (map['wordSpacing'] as num?)?.toDouble() ?? 4.0,
        font: DyslexiaFont.values[(map['font'] as int? ?? 0)
            .clamp(0, DyslexiaFont.values.length - 1)],
        colorTheme: AppColorTheme.values[(map['colorTheme'] as int? ?? 1)
            .clamp(0, AppColorTheme.values.length - 1)],
        preset: DisplayPreset.values[(map['preset'] as int? ?? 0)
            .clamp(0, DisplayPreset.values.length - 1)],
      );

  DisplaySettingsModel copyWith({
    double? fontSize,
    double? lineSpacing,
    double? letterSpacing,
    double? wordSpacing,
    DyslexiaFont? font,
    AppColorTheme? colorTheme,
    DisplayPreset? preset,
  }) =>
      DisplaySettingsModel(
        fontSize: fontSize ?? this.fontSize,
        lineSpacing: lineSpacing ?? this.lineSpacing,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        wordSpacing: wordSpacing ?? this.wordSpacing,
        font: font ?? this.font,
        colorTheme: colorTheme ?? this.colorTheme,
        preset: preset ?? this.preset,
      );
}
