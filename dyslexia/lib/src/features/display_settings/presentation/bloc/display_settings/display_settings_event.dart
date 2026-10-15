part of 'display_settings_bloc.dart';

abstract class DisplaySettingsEvent extends Equatable {
  const DisplaySettingsEvent();

  @override
  List<Object?> get props => [];
}

class UpdateFontSizeEvent extends DisplaySettingsEvent {
  final double fontSize;
  const UpdateFontSizeEvent(this.fontSize);
  @override
  List<Object?> get props => [fontSize];
}

class UpdateLineSpacingEvent extends DisplaySettingsEvent {
  final double lineSpacing;
  const UpdateLineSpacingEvent(this.lineSpacing);
  @override
  List<Object?> get props => [lineSpacing];
}

class UpdateLetterSpacingEvent extends DisplaySettingsEvent {
  final double letterSpacing;
  const UpdateLetterSpacingEvent(this.letterSpacing);
  @override
  List<Object?> get props => [letterSpacing];
}

class UpdateWordSpacingEvent extends DisplaySettingsEvent {
  final double wordSpacing;
  const UpdateWordSpacingEvent(this.wordSpacing);
  @override
  List<Object?> get props => [wordSpacing];
}

class UpdateFontEvent extends DisplaySettingsEvent {
  final DyslexiaFont font;
  const UpdateFontEvent(this.font);
  @override
  List<Object?> get props => [font];
}

class UpdateColorThemeEvent extends DisplaySettingsEvent {
  final AppColorTheme colorTheme;
  const UpdateColorThemeEvent(this.colorTheme);
  @override
  List<Object?> get props => [colorTheme];
}

class ApplyPresetEvent extends DisplaySettingsEvent {
  final DisplayPreset preset;
  const ApplyPresetEvent(this.preset);
  @override
  List<Object?> get props => [preset];
}

class ToggleRulerEvent extends DisplaySettingsEvent {
  const ToggleRulerEvent();
}

class ToggleSyllablesEvent extends DisplaySettingsEvent {
  const ToggleSyllablesEvent();
}

class ToggleDarkModeEvent extends DisplaySettingsEvent {
  final bool isDarkMode;
  const ToggleDarkModeEvent(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}