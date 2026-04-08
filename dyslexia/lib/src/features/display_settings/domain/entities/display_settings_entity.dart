import 'package:equatable/equatable.dart';

enum DyslexiaFont { openDyslexic, lexend, arial, verdana }

enum AppColorTheme { light, dark, yellowOnBlack, creamOnBlue }

enum DisplayPreset { defaultPreset, dyslexiaFriendly, highContrast, nightMode }

class DisplaySettingsEntity extends Equatable {
  final double fontSize;
  final DyslexiaFont font;
  final AppColorTheme colorTheme;
  final DisplayPreset preset;

  const DisplaySettingsEntity({
    required this.fontSize,
    required this.font,
    required this.colorTheme,
    required this.preset,
  });

  @override
  List<Object?> get props => [fontSize, font, colorTheme, preset];
}
