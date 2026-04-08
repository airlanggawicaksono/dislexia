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
    on<UpdateFontEvent>(_updateFont);
    on<UpdateColorThemeEvent>(_updateColorTheme);
    on<ApplyPresetEvent>(_applyPreset);
  }

  void _updateFontSize(
      UpdateFontSizeEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings.copyWith(fontSize: event.fontSize)));
  }

  void _updateFont(UpdateFontEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings.copyWith(font: event.font)));
  }

  void _updateColorTheme(
      UpdateColorThemeEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(
        settings: state.settings.copyWith(colorTheme: event.colorTheme)));
  }

  void _applyPreset(
      ApplyPresetEvent event, Emitter<DisplaySettingsState> emit) {
    emit(state.copyWith(settings: _presetToModel(event.preset)));
  }

  DisplaySettingsModel _presetToModel(DisplayPreset preset) {
    return switch (preset) {
      DisplayPreset.defaultPreset => DisplaySettingsModel.defaults(),
      DisplayPreset.dyslexiaFriendly => const DisplaySettingsModel(
          fontSize: 18.0,
          font: DyslexiaFont.openDyslexic,
          colorTheme: AppColorTheme.creamOnBlue,
          preset: DisplayPreset.dyslexiaFriendly,
        ),
      DisplayPreset.highContrast => const DisplaySettingsModel(
          fontSize: 20.0,
          font: DyslexiaFont.lexend,
          colorTheme: AppColorTheme.yellowOnBlack,
          preset: DisplayPreset.highContrast,
        ),
      DisplayPreset.nightMode => const DisplaySettingsModel(
          fontSize: 16.0,
          font: DyslexiaFont.lexend,
          colorTheme: AppColorTheme.dark,
          preset: DisplayPreset.nightMode,
        ),
    };
  }

  @override
  DisplaySettingsState? fromJson(Map<String, dynamic> json) {
    try {
      return DisplaySettingsState(
          settings: DisplaySettingsModel.fromMap(json));
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
