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
  dark,
  lightBlue,
  grey,
}

enum DisplayPreset {
  defaultPreset,
  dyslexiaFriendly,
  highContrast,
  nightMode,
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
  });

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
      ];
}
