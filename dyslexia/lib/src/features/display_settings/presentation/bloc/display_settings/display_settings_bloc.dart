import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../features/display_settings/data/models/display_settings_model.dart';
import '../../../../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../../domain/repositories/display_settings_repository.dart';

part 'display_settings_event.dart';
part 'display_settings_state.dart';

class DisplaySettingsBloc
    extends Bloc<DisplaySettingsEvent, DisplaySettingsState> {
  final DisplaySettingsRepository _repository;
  Timer? _saveDebounce;

  DisplaySettingsBloc(this._repository)
      : super(DisplaySettingsState(settings: DisplaySettingsModel.defaults())) {
    _load();
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

  Future<void> _load() async {
    try {
      final settings = await _repository.load();
      // Only apply loaded settings if the state hasn't been mutated yet
      // (still at defaults). This prevents the async load from overwriting
      // a user-initiated change that arrived before load completed.
      if (!isClosed && state.settings == DisplaySettingsModel.defaults()) {
        emit(DisplaySettingsState(settings: settings));
      }
    } catch (_) {
      // Keep defaults on load failure
    }
  }

  @override
  Future<void> close() {
    _saveDebounce?.cancel();
    return super.close();
  }

  /// Debounced save: emits immediately for responsive UI, persists
  /// after a 300ms pause to avoid blocking slider drags with Hive writes.
  void _debouncedSave(DisplaySettingsEntity settings) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      _repository.save(settings).catchError((_) {});
    });
  }

  void _updateFontSize(
      UpdateFontSizeEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(fontSize: event.fontSize);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateLineSpacing(
      UpdateLineSpacingEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(lineSpacing: event.lineSpacing);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateLetterSpacing(
      UpdateLetterSpacingEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(letterSpacing: event.letterSpacing);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateWordSpacing(
      UpdateWordSpacingEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(wordSpacing: event.wordSpacing);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateFont(
      UpdateFontEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(font: event.font);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateColorTheme(
      UpdateColorThemeEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(colorTheme: event.colorTheme);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _applyPreset(
      ApplyPresetEvent event, Emitter<DisplaySettingsState> emit) {
    // Presets only change typography / colour / font. Per-user
    // accessibility toggles (ruler, syllable dots) are kept as-is
    // so switching presets never silently turns the reader's
    // assistive features on or off.
    final presetModel = _presetToModel(event.preset);
    final updated = state.settings.copyWith(
      fontSize: presetModel.fontSize,
      lineSpacing: presetModel.lineSpacing,
      letterSpacing: presetModel.letterSpacing,
      wordSpacing: presetModel.wordSpacing,
      font: presetModel.font,
      colorTheme: presetModel.colorTheme,
      preset: presetModel.preset,
    );
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _toggleRuler(
      ToggleRulerEvent event, Emitter<DisplaySettingsState> emit) {
    final updated =
        state.settings.copyWith(rulerEnabled: !state.settings.rulerEnabled);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _toggleSyllables(
      ToggleSyllablesEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings
        .copyWith(syllablesEnabled: !state.settings.syllablesEnabled);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
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
}
