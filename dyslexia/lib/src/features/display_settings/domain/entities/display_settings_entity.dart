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
}

enum DisplayPreset { defaultPreset, dyslexiaFriendly, highContrast, nightMode }

class DisplaySettingsEntity extends Equatable {
  final double fontSize;
  final double lineSpacing;
  final double letterSpacing;
  final double wordSpacing;
  final DyslexiaFont font;
  final AppColorTheme colorTheme;
  final DisplayPreset preset;

  const DisplaySettingsEntity({
    required this.fontSize,
    required this.lineSpacing,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.font,
    required this.colorTheme,
    required this.preset,
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
      ];
}
