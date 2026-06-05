import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../../../features/display_settings/data/models/display_settings_model.dart';
import '../../../../../features/display_settings/domain/entities/display_settings_entity.dart';

part 'display_settings_event.dart';
part 'display_settings_state.dart';

class DisplaySettingsBloc
    extends HydratedBloc<DisplaySettingsEvent, DisplaySettingsState> {
  DisplaySettingsBloc()
      : super(DisplaySettingsState(settings: DisplaySettingsModel.defaults())) {
    on<UpdateFontSizeEvent>(_updateFontSize);
    on<UpdateLineSpacingEvent>(_updateLineSpacing);
    on<UpdateLetterSpacingEvent>(_updateLetterSpacing);
    on<UpdateWordSpacingEvent>(_updateWordSpacing);
    on<UpdateFontEvent>(_updateFont);
    on<UpdateColorThemeEvent>(_updateColorTheme);
    on<ApplyPresetEvent>(_applyPreset);
    on<ToggleRulerEvent>(_toggleRuler);
    on<ToggleSyllablesEvent>(_toggleSyllables);
  }

  void _updateFontSize(
      UpdateFontSizeEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings.copyWith(fontSize: event.fontSize)));
  }

  void _updateLineSpacing(
      UpdateLineSpacingEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings.copyWith(lineSpacing: event.lineSpacing)));
  }

  void _updateLetterSpacing(
      UpdateLetterSpacingEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings.copyWith(letterSpacing: event.letterSpacing)));
  }

  void _updateWordSpacing(
      UpdateWordSpacingEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings.copyWith(wordSpacing: event.wordSpacing)));
  }

  void _updateFont(UpdateFontEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(settings: state.settings.copyWith(font: event.font)));
  }

  void _updateColorTheme(
      UpdateColorThemeEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings.copyWith(colorTheme: event.colorTheme)));
  }

  void _applyPreset(
      ApplyPresetEvent event, Emitter<DisplaySettingsState> emit) {
    // Presets only change typography / colour / font. Per-user
    // accessibility toggles (ruler, syllable dots) are kept as-is
    // so switching presets never silently turns the reader's
    // assistive features on or off.
    final presetModel = _presetToModel(event.preset);
    emit(state.copyWith(
      settings: state.settings.copyWith(
        fontSize: presetModel.fontSize,
        lineSpacing: presetModel.lineSpacing,
        letterSpacing: presetModel.letterSpacing,
        wordSpacing: presetModel.wordSpacing,
        font: presetModel.font,
        colorTheme: presetModel.colorTheme,
        preset: presetModel.preset,
      ),
    ));
  }

  void _toggleRuler(
      ToggleRulerEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings
            .copyWith(rulerEnabled: !state.settings.rulerEnabled)));
  }

  void _toggleSyllables(
      ToggleSyllablesEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings
            .copyWith(syllablesEnabled: !state.settings.syllablesEnabled)));
  }

  DisplaySettingsModel _presetToModel(DisplayPreset preset) {
    return switch (preset) {
      DisplayPreset.defaultPreset => DisplaySettingsModel.defaults(),
      DisplayPreset.dyslexiaFriendly => DisplaySettingsModel(
          fontSize: 20.0,
          lineSpacing: 2.0,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.openDyslexic,
          colorTheme: AppColorTheme.cream,
          preset: DisplayPreset.dyslexiaFriendly,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
      DisplayPreset.highContrast => DisplaySettingsModel(
          fontSize: 22.0,
          lineSpacing: 2.0,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.plusJakartaSans,
          colorTheme: AppColorTheme.dark,
          preset: DisplayPreset.highContrast,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
      DisplayPreset.nightMode => DisplaySettingsModel(
          fontSize: 18.0,
          lineSpacing: 1.8,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.plusJakartaSans,
          colorTheme: AppColorTheme.dark,
          preset: DisplayPreset.nightMode,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
      DisplayPreset.lightBlueTheme => DisplaySettingsModel(
          fontSize: 18.0,
          lineSpacing: 1.8,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.sassoonPrimary,
          colorTheme: AppColorTheme.lightBlue,
          preset: DisplayPreset.lightBlueTheme,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
      DisplayPreset.greyTheme => DisplaySettingsModel(
          fontSize: 18.0,
          lineSpacing: 1.8,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.tahoma,
          colorTheme: AppColorTheme.grey,
          preset: DisplayPreset.greyTheme,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
      DisplayPreset.lavenderTheme => DisplaySettingsModel(
          fontSize: 18.0,
          lineSpacing: 1.8,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.sassoonPrimary,
          colorTheme: AppColorTheme.lavender,
          preset: DisplayPreset.lavenderTheme,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
      DisplayPreset.whiteTheme => DisplaySettingsModel(
          fontSize: 18.0,
          lineSpacing: 1.5,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.openDyslexic,
          colorTheme: AppColorTheme.white,
          preset: DisplayPreset.whiteTheme,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
      DisplayPreset.skyBlueTheme => DisplaySettingsModel(
          fontSize: 18.0,
          lineSpacing: 1.8,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.plusJakartaSans,
          colorTheme: AppColorTheme.skyBlue,
          preset: DisplayPreset.skyBlueTheme,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
      DisplayPreset.mintGreenTheme => DisplaySettingsModel(
          fontSize: 18.0,
          lineSpacing: 1.8,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.lexend,
          colorTheme: AppColorTheme.mintGreen,
          preset: DisplayPreset.mintGreenTheme,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
      DisplayPreset.peachTheme => DisplaySettingsModel(
          fontSize: 18.0,
          lineSpacing: 1.8,
          letterSpacing: 0.5,
          wordSpacing: 4.0,
          font: DyslexiaFont.sassoonPrimary,
          colorTheme: AppColorTheme.peach,
          preset: DisplayPreset.peachTheme,
          rulerEnabled: true,
          syllablesEnabled: true,
        ),
    };
  }

  @override
  DisplaySettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return DisplaySettingsState(settings: DisplaySettingsModel.fromMap(json));
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(DisplaySettingsState state) {
    try {
      return state.settings.toMap();
    } catch (_) {
      return null;
    }
  }
}
