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
    required super.rulerEnabled,
    required super.syllablesEnabled,
  });

  factory DisplaySettingsModel.defaults() => const DisplaySettingsModel(
        fontSize: 18.0,
        lineSpacing: 1.5,
        letterSpacing: 0.5,
        wordSpacing: 4.0,
        font: DyslexiaFont.openDyslexic,
        colorTheme: AppColorTheme.cream,
        preset: DisplayPreset.defaultPreset,
        rulerEnabled: true,
        syllablesEnabled: true,
      );

  Map<String, dynamic> toMap() => {
        'fontSize': fontSize,
        'lineSpacing': lineSpacing,
        'letterSpacing': letterSpacing,
        'wordSpacing': wordSpacing,
        'font': font.index,
        'colorTheme': colorTheme.name,
        'preset': preset.name,
        'rulerEnabled': rulerEnabled,
        'syllablesEnabled': syllablesEnabled,
      };

  factory DisplaySettingsModel.fromMap(Map<String, dynamic> map) =>
      DisplaySettingsModel(
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0,
        lineSpacing: (map['lineSpacing'] as num?)?.toDouble() ?? 1.5,
        letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 0.5,
        wordSpacing: (map['wordSpacing'] as num?)?.toDouble() ?? 4.0,
        font: DyslexiaFont.values[(map['font'] as int? ?? 0)
            .clamp(0, DyslexiaFont.values.length - 1)],
        colorTheme: _safeColorTheme(map['colorTheme']),
        preset: _safePreset(map['preset']),
        rulerEnabled: map['rulerEnabled'] as bool? ?? true,
        syllablesEnabled: map['syllablesEnabled'] as bool? ?? true,
      );

  /// Parses the persisted color-theme value. New writes store the enum name so
  /// a removed theme can never alias a live one; legacy numeric indices are
  /// migrated across the removal of `AppColorTheme.dark` (old index 7 falls
  /// back to white, later indices shift down). Unknown names fall back to
  /// white rather than crashing.
  static AppColorTheme _safeColorTheme(dynamic raw) {
    if (raw is String) {
      return AppColorTheme.values.asNameMap()[raw] ?? AppColorTheme.white;
    }
    if (raw is num) {
      const removedDarkIndex = 7; // AppColorTheme.dark was removed
      var idx = raw.toInt();
      if (idx == removedDarkIndex) return AppColorTheme.white;
      if (idx > removedDarkIndex) idx -= 1;
      return AppColorTheme.values[idx.clamp(0, AppColorTheme.values.length - 1)];
    }
    return AppColorTheme.cream; // historical default
  }

  /// Parses the persisted preset value: an enum name, or a legacy numeric
  /// index migrated across the removal of `DisplayPreset.nightMode` (old index
  /// 3 falls back to the default preset, later indices shift down). Unknown
  /// names fall back to the default preset.
  static DisplayPreset _safePreset(dynamic raw) {
    if (raw is String) {
      return DisplayPreset.values.asNameMap()[raw] ?? DisplayPreset.defaultPreset;
    }
    if (raw is num) {
      const removedNightModeIndex = 3; // DisplayPreset.nightMode was removed
      var idx = raw.toInt();
      if (idx == removedNightModeIndex) return DisplayPreset.defaultPreset;
      if (idx > removedNightModeIndex) idx -= 1;
      return DisplayPreset.values[idx.clamp(0, DisplayPreset.values.length - 1)];
    }
    return DisplayPreset.defaultPreset;
  }

  @override
  DisplaySettingsModel copyWith({
    double? fontSize,
    double? lineSpacing,
    double? letterSpacing,
    double? wordSpacing,
    DyslexiaFont? font,
    AppColorTheme? colorTheme,
    DisplayPreset? preset,
    bool? rulerEnabled,
    bool? syllablesEnabled,
  }) =>
      DisplaySettingsModel(
        fontSize: fontSize ?? this.fontSize,
        lineSpacing: lineSpacing ?? this.lineSpacing,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        wordSpacing: wordSpacing ?? this.wordSpacing,
        font: font ?? this.font,
        colorTheme: colorTheme ?? this.colorTheme,
        preset: preset ?? this.preset,
        rulerEnabled: rulerEnabled ?? this.rulerEnabled,
        syllablesEnabled: syllablesEnabled ?? this.syllablesEnabled,
      );
}
