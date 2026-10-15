import 'package:equatable/equatable.dart';

enum DyslexiaFont {
  openDyslexic,
  plusJakartaSans,
  arial,
  calibri,
  lexend,
  sassoonPrimary,
  tahoma,
  weezerFont,
  verdana,
  trebuchetMS,
  helvetica,
  comicSansMS,
}

enum AppColorTheme {
  white,
  cream,
  softYellow,
  mintGreen,
  lavender,
  skyBlue,
  peach,
  lightBlue,
  grey,
}

enum DisplayPreset {
  defaultPreset,
  dyslexiaFriendly,
  highContrast,
  lightBlueTheme,
  greyTheme,
  lavenderTheme,
  whiteTheme,
  skyBlueTheme,
  mintGreenTheme,
  peachTheme,
}

class DisplaySettingsEntity extends Equatable {
  final double fontSize;
  final double lineSpacing;
  final double letterSpacing;
  final double wordSpacing;
  final DyslexiaFont font;
  final AppColorTheme colorTheme;
  final DisplayPreset preset;
  final bool rulerEnabled;
  final bool syllablesEnabled;
  final bool isDarkMode; // ✅ PERBAIKAN: Tipe data bool yang benar

  const DisplaySettingsEntity({
    required this.fontSize,
    required this.lineSpacing,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.font,
    required this.colorTheme,
    required this.preset,
    required this.rulerEnabled,
    required this.syllablesEnabled,
    required this.isDarkMode, // ✅ PERBAIKAN: Required parameter yang benar
  });

  DisplaySettingsEntity copyWith({
    double? fontSize,
    double? lineSpacing,
    double? letterSpacing,
    double? wordSpacing,
    DyslexiaFont? font,
    AppColorTheme? colorTheme,
    DisplayPreset? preset,
    bool? rulerEnabled,
    bool? syllablesEnabled,
    bool? isDarkMode, // ✅ PERBAIKAN: Tipe data bool yang benar
  }) =>
      DisplaySettingsEntity(
        fontSize: fontSize ?? this.fontSize,
        lineSpacing: lineSpacing ?? this.lineSpacing,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        wordSpacing: wordSpacing ?? this.wordSpacing,
        font: font ?? this.font,
        colorTheme: colorTheme ?? this.colorTheme,
        preset: preset ?? this.preset,
        rulerEnabled: rulerEnabled ?? this.rulerEnabled,
        syllablesEnabled: syllablesEnabled ?? this.syllablesEnabled,
        isDarkMode: isDarkMode ?? this.isDarkMode, // ✅ PERBAIKAN: Diteruskan ke constructor
      );

  @override
  List<Object?> get props => [
        fontSize,
        lineSpacing,
        letterSpacing,
        wordSpacing,
        font,
        colorTheme,
        preset,
        rulerEnabled,
        syllablesEnabled,
        isDarkMode, // ✅ PERBAIKAN: Ditambahkan ke props agar Equatable bekerja dengan benar
      ];
}