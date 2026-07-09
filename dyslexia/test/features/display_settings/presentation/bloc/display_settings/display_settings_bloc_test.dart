import 'package:dyslexia/src/features/display_settings/data/models/display_settings_model.dart';
import 'package:dyslexia/src/features/display_settings/domain/entities/display_settings_entity.dart';
import 'package:dyslexia/src/features/display_settings/domain/repositories/display_settings_repository.dart';
import 'package:dyslexia/src/features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements DisplaySettingsRepository {}

/// The bloc persists through a 300ms debounce ([_debouncedSave]). Tests that
/// assert on `save(...)` must let that window elapse; a `Duration.zero` yield
/// only flushes the synchronous state emit, not the pending timer.
const _debounceWindow = Duration(milliseconds: 350);
Future<void> _flush() => Future<void>.delayed(_debounceWindow);
Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  late MockRepository mockRepository;
  late DisplaySettingsBloc bloc;

  setUpAll(() {
    // mocktail needs a fallback for the DisplaySettingsEntity type used in
    // `save(any())`. DisplaySettingsModel is-a DisplaySettingsEntity.
    registerFallbackValue(DisplaySettingsModel.defaults());
  });

  setUp(() {
    mockRepository = MockRepository();
    // The bloc calls _load() in its constructor, which calls repository.load().
    when(() => mockRepository.load()).thenAnswer((_) async => DisplaySettingsModel.defaults());
    when(() => mockRepository.save(any())).thenAnswer((_) async {});
    bloc = DisplaySettingsBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('initial state', () {
    test('loads settings from repository on creation', () async {
      await _tick(); // let async _load complete

      expect(bloc.state.settings, equals(DisplaySettingsModel.defaults()));
      verify(() => mockRepository.load()).called(1);
    });
  });

  group('UpdateFontSizeEvent', () {
    test('emits new state with updated fontSize and saves', () async {
      await _tick();

      bloc.add(UpdateFontSizeEvent(22.0));
      await _flush();

      expect(bloc.state.settings.fontSize, 22.0);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateLineSpacingEvent', () {
    test('emits new state with updated lineSpacing and saves', () async {
      await _tick();

      bloc.add(UpdateLineSpacingEvent(2.0));
      await _flush();

      expect(bloc.state.settings.lineSpacing, 2.0);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateLetterSpacingEvent', () {
    test('emits new state with updated letterSpacing and saves', () async {
      await _tick();

      bloc.add(UpdateLetterSpacingEvent(1.0));
      await _flush();

      expect(bloc.state.settings.letterSpacing, 1.0);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateWordSpacingEvent', () {
    test('emits new state with updated wordSpacing and saves', () async {
      await _tick();

      bloc.add(UpdateWordSpacingEvent(8.0));
      await _flush();

      expect(bloc.state.settings.wordSpacing, 8.0);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateFontEvent', () {
    test('emits new state with updated font and saves', () async {
      await _tick();

      bloc.add(UpdateFontEvent(DyslexiaFont.arial));
      await _flush();

      expect(bloc.state.settings.font, DyslexiaFont.arial);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateColorThemeEvent', () {
    test('emits new state with updated colorTheme and saves', () async {
      await _tick();

      bloc.add(UpdateColorThemeEvent(AppColorTheme.dark));
      await _flush();

      expect(bloc.state.settings.colorTheme, AppColorTheme.dark);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('ApplyPresetEvent', () {
    test('emits new state with preset font and saves', () async {
      await _tick();

      bloc.add(ApplyPresetEvent(DisplayPreset.highContrast));
      await _flush();

      expect(bloc.state.settings.fontSize, 22.0);
      expect(bloc.state.settings.font, DyslexiaFont.plusJakartaSans);
      expect(bloc.state.settings.colorTheme, AppColorTheme.dark);
      verify(() => mockRepository.save(any())).called(1);
    });

    test('preserves rulerEnabled and syllablesEnabled toggles', () async {
      await _tick();

      // Start with toggles off
      bloc.add(ToggleRulerEvent());
      bloc.add(ToggleSyllablesEvent());
      await _tick();

      // Apply a preset
      bloc.add(ApplyPresetEvent(DisplayPreset.nightMode));
      await _tick();

      expect(bloc.state.settings.rulerEnabled, false);
      expect(bloc.state.settings.syllablesEnabled, false);
    });
  });

  group('ToggleRulerEvent', () {
    test('toggles rulerEnabled and saves', () async {
      await _tick();

      // Space the two toggles past the debounce window so each persists
      // independently instead of the second cancelling the first's timer.
      bloc.add(ToggleRulerEvent());
      await _flush();
      expect(bloc.state.settings.rulerEnabled, false);

      bloc.add(ToggleRulerEvent());
      await _flush();
      expect(bloc.state.settings.rulerEnabled, true);

      verify(() => mockRepository.save(any())).called(2);
    });
  });

  group('ToggleSyllablesEvent', () {
    test('toggles syllablesEnabled and saves', () async {
      await _tick();

      bloc.add(ToggleSyllablesEvent());
      await _flush();

      expect(bloc.state.settings.syllablesEnabled, false);
      verify(() => mockRepository.save(any())).called(1);
    });
  });
}
