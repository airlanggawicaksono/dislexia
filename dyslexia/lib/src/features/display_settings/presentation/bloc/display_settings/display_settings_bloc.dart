import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ✅ PERBAIKAN: Gunakan Absolute Package Import agar tidak tersesat
import 'package:dyslexia/src/features/display_settings/data/models/display_settings_model.dart';
import 'package:dyslexia/src/features/display_settings/domain/entities/display_settings_entity.dart';
import 'package:dyslexia/src/features/display_settings/domain/repositories/display_settings_repository.dart';

part 'display_settings_event.dart';
part 'display_settings_state.dart';

class DisplaySettingsBloc extends Bloc<DisplaySettingsEvent, DisplaySettingsState> {
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
    on<ToggleDarkModeEvent>(_toggleDarkMode);
  }

  Future<void> _load() async {
    try {
      final settings = await _repository.load();
      if (!isClosed) {
        emit(DisplaySettingsState(settings: settings));
      }
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _saveDebounce?.cancel();
    return super.close();
  }

  void _debouncedSave(DisplaySettingsEntity settings) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      _repository.save(settings).catchError((_) {});
    });
  }

  void _updateFontSize(UpdateFontSizeEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(fontSize: event.fontSize);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateLineSpacing(UpdateLineSpacingEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(lineSpacing: event.lineSpacing);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateLetterSpacing(UpdateLetterSpacingEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(letterSpacing: event.letterSpacing);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateWordSpacing(UpdateWordSpacingEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(wordSpacing: event.wordSpacing);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateFont(UpdateFontEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(font: event.font);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _updateColorTheme(UpdateColorThemeEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(colorTheme: event.colorTheme);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _toggleDarkMode(ToggleDarkModeEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(isDarkMode: event.isDarkMode);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _applyPreset(ApplyPresetEvent event, Emitter<DisplaySettingsState> emit) {
    final presetModel = _presetToModel(event.preset);
    final updated = state.settings.copyWith(
      fontSize: presetModel.fontSize,
      lineSpacing: presetModel.lineSpacing,
      letterSpacing: presetModel.letterSpacing,
      wordSpacing: presetModel.wordSpacing,
      font: presetModel.font,
      colorTheme: presetModel.colorTheme,
      preset: presetModel.preset,
      rulerEnabled: state.settings.rulerEnabled,
      syllablesEnabled: state.settings.syllablesEnabled,
      isDarkMode: state.settings.isDarkMode, 
    );
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _toggleRuler(ToggleRulerEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(rulerEnabled: !state.settings.rulerEnabled);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  void _toggleSyllables(ToggleSyllablesEvent event, Emitter<DisplaySettingsState> emit) {
    final updated = state.settings.copyWith(syllablesEnabled: !state.settings.syllablesEnabled);
    emit(state.copyWith(settings: updated));
    _debouncedSave(updated);
  }

  DisplaySettingsModel _presetToModel(DisplayPreset preset) {
    return switch (preset) {
      DisplayPreset.defaultPreset => DisplaySettingsModel.defaults(),
      DisplayPreset.dyslexiaFriendly => DisplaySettingsModel(
          fontSize: 20.0, lineSpacing: 2.0, letterSpacing: 0.5, wordSpacing: 4.0,
          font: DyslexiaFont.openDyslexic, colorTheme: AppColorTheme.cream,
          preset: DisplayPreset.dyslexiaFriendly, rulerEnabled: true, syllablesEnabled: true,
          isDarkMode: state.settings.isDarkMode,
        ),
      DisplayPreset.highContrast => DisplaySettingsModel(
          fontSize: 22.0, lineSpacing: 2.0, letterSpacing: 0.5, wordSpacing: 4.0,
          font: DyslexiaFont.plusJakartaSans, colorTheme: AppColorTheme.white,
          preset: DisplayPreset.highContrast, rulerEnabled: true, syllablesEnabled: true,
          isDarkMode: state.settings.isDarkMode,
        ),
      // Tambahkan case lain sesuai kebutuhan, atau biarkan default menangani sisanya
      _ => DisplaySettingsModel.defaults().copyWith(preset: preset),
    };
  }
}