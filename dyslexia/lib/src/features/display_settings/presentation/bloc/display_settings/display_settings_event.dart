part of 'display_settings_bloc.dart';

abstract class DisplaySettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDisplaySettingsEvent extends DisplaySettingsEvent {}

class UpdateFontSizeEvent extends DisplaySettingsEvent {
  final double fontSize;
  UpdateFontSizeEvent(this.fontSize);

  @override
  List<Object?> get props => [fontSize];
}

class UpdateFontEvent extends DisplaySettingsEvent {
  final DyslexiaFont font;
  UpdateFontEvent(this.font);

  @override
  List<Object?> get props => [font];
}

class UpdateColorThemeEvent extends DisplaySettingsEvent {
  final AppColorTheme colorTheme;
  UpdateColorThemeEvent(this.colorTheme);

  @override
  List<Object?> get props => [colorTheme];
}

class ApplyPresetEvent extends DisplaySettingsEvent {
  final DisplayPreset preset;
  ApplyPresetEvent(this.preset);

  @override
  List<Object?> get props => [preset];
}
