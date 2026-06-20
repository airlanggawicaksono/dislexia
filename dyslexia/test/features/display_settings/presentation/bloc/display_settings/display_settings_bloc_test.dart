import 'package:dyslexia/src/features/display_settings/data/models/display_settings_model.dart';
import 'package:dyslexia/src/features/display_settings/domain/entities/display_settings_entity.dart';
import 'package:dyslexia/src/features/display_settings/domain/repositories/display_settings_repository.dart';
import 'package:dyslexia/src/features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements DisplaySettingsRepository {}

void main() {
  late MockRepository mockRepository;
  late DisplaySettingsBloc bloc;

  setUp(() {
    mockRepository = MockRepository();
    // The bloc calls _load() in its constructor, which calls repository.load().
    when(() => mockRepository.load()).thenAnswer((_) async => DisplaySettingsModel.defaults());
    bloc = DisplaySettingsBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('initial state', () {
    test('loads settings from repository on creation', () async {
      await Future<void>.delayed(Duration.zero); // let async _load complete

      expect(bloc.state.settings, equals(DisplaySettingsModel.defaults()));
      verify(() => mockRepository.load()).called(1);
    });
  });

  group('UpdateFontSizeEvent', () {
    test('emits new state with updated fontSize and saves', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      bloc.add(UpdateFontSizeEvent(22.0));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.fontSize, 22.0);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateLineSpacingEvent', () {
    test('emits new state with updated lineSpacing and saves', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      bloc.add(UpdateLineSpacingEvent(2.0));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.lineSpacing, 2.0);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateLetterSpacingEvent', () {
    test('emits new state with updated letterSpacing and saves', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      bloc.add(UpdateLetterSpacingEvent(1.0));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.letterSpacing, 1.0);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateWordSpacingEvent', () {
    test('emits new state with updated wordSpacing and saves', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      bloc.add(UpdateWordSpacingEvent(8.0));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.wordSpacing, 8.0);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateFontEvent', () {
    test('emits new state with updated font and saves', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      bloc.add(UpdateFontEvent(DyslexiaFont.arial));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.font, DyslexiaFont.arial);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('UpdateColorThemeEvent', () {
    test('emits new state with updated colorTheme and saves', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      bloc.add(UpdateColorThemeEvent(AppColorTheme.dark));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.colorTheme, AppColorTheme.dark);
      verify(() => mockRepository.save(any())).called(1);
    });
  });

  group('ApplyPresetEvent', () {
    test('emits new state with preset font and saves', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      bloc.add(ApplyPresetEvent(DisplayPreset.highContrast));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.fontSize, 22.0);
      expect(bloc.state.settings.font, DyslexiaFont.plusJakartaSans);
      expect(bloc.state.settings.colorTheme, AppColorTheme.dark);
      verify(() => mockRepository.save(any())).called(1);
    });

    test('preserves rulerEnabled and syllablesEnabled toggles', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      // Start with toggles off
      bloc.add(ToggleRulerEvent());
      bloc.add(ToggleSyllablesEvent());
      await Future<void>.delayed(Duration.zero);

      // Apply a preset
      bloc.add(ApplyPresetEvent(DisplayPreset.nightMode));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.rulerEnabled, false);
      expect(bloc.state.settings.syllablesEnabled, false);
    });
  });

  group('ToggleRulerEvent', () {
    test('toggles rulerEnabled and saves', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      bloc.add(ToggleRulerEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.rulerEnabled, false);

      bloc.add(ToggleRulerEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.rulerEnabled, true);
      verify(() => mockRepository.save(any())).called(2);
    });
  });

  group('ToggleSyllablesEvent', () {
    test('toggles syllablesEnabled and saves', () async {
      await Future<void>.delayed(Duration.zero);
      when(() => mockRepository.save(any())).thenAnswer((_) async {});

      bloc.add(ToggleSyllablesEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.settings.syllablesEnabled, false);
      verify(() => mockRepository.save(any())).called(1);
    });
  });
}
