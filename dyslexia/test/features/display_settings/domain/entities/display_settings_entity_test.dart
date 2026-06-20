import 'package:dyslexia/src/features/display_settings/domain/entities/display_settings_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaults = DisplaySettingsEntity(
    fontSize: 18.0,
    lineSpacing: 1.5,
    letterSpacing: 0.5,
    wordSpacing: 4.0,
    font: DyslexiaFont.openDyslexic,
    colorTheme: AppColorTheme.cream,
    preset: DisplayPreset.defaultPreset,
    rulerEnabled: true,
    syllablesEnabled: true,
  );

  group('DisplaySettingsEntity', () {
    test('props are correct', () {
      expect(defaults.props, [
        18.0,
        1.5,
        0.5,
        4.0,
        DyslexiaFont.openDyslexic,
        AppColorTheme.cream,
        DisplayPreset.defaultPreset,
        true,
        true,
      ]);
    });

    test('equality works', () {
      const a = DisplaySettingsEntity(
        fontSize: 18.0,
        lineSpacing: 1.5,
        letterSpacing: 0.5,
        wordSpacing: 4.0,
        font: DyslexiaFont.openDyslexic,
        colorTheme: AppColorTheme.cream,
        preset: DisplayPreset.defaultPreset,
        rulerEnabled: true,
        syllablesEnabled: true,
      );
      const b = DisplaySettingsEntity(
        fontSize: 18.0,
        lineSpacing: 1.5,
        letterSpacing: 0.5,
        wordSpacing: 4.0,
        font: DyslexiaFont.openDyslexic,
        colorTheme: AppColorTheme.cream,
        preset: DisplayPreset.defaultPreset,
        rulerEnabled: true,
        syllablesEnabled: true,
      );
      expect(a, equals(b));
    });

    test('inequality detects differences', () {
      const different = DisplaySettingsEntity(
        fontSize: 20.0,
        lineSpacing: 1.5,
        letterSpacing: 0.5,
        wordSpacing: 4.0,
        font: DyslexiaFont.openDyslexic,
        colorTheme: AppColorTheme.cream,
        preset: DisplayPreset.defaultPreset,
        rulerEnabled: true,
        syllablesEnabled: true,
      );
      expect(different, isNot(equals(defaults)));
    });
  });

  group('copyWith', () {
    test('returns same object when no arguments are provided', () {
      expect(defaults.copyWith(), equals(defaults));
    });

    test('updates fontSize', () {
      final result = defaults.copyWith(fontSize: 22.0);
      expect(result.fontSize, 22.0);
      expect(result.lineSpacing, defaults.lineSpacing);
    });

    test('updates lineSpacing', () {
      final result = defaults.copyWith(lineSpacing: 2.0);
      expect(result.lineSpacing, 2.0);
      expect(result.fontSize, defaults.fontSize);
    });

    test('updates letterSpacing', () {
      final result = defaults.copyWith(letterSpacing: 1.0);
      expect(result.letterSpacing, 1.0);
    });

    test('updates wordSpacing', () {
      final result = defaults.copyWith(wordSpacing: 8.0);
      expect(result.wordSpacing, 8.0);
    });

    test('updates font', () {
      final result = defaults.copyWith(font: DyslexiaFont.arial);
      expect(result.font, DyslexiaFont.arial);
    });

    test('updates colorTheme', () {
      final result = defaults.copyWith(colorTheme: AppColorTheme.dark);
      expect(result.colorTheme, AppColorTheme.dark);
    });

    test('updates preset', () {
      final result =
          defaults.copyWith(preset: DisplayPreset.dyslexiaFriendly);
      expect(result.preset, DisplayPreset.dyslexiaFriendly);
    });

    test('toggles rulerEnabled', () {
      final result = defaults.copyWith(rulerEnabled: false);
      expect(result.rulerEnabled, false);
    });

    test('toggles syllablesEnabled', () {
      final result = defaults.copyWith(syllablesEnabled: false);
      expect(result.syllablesEnabled, false);
    });

    test('combines multiple fields', () {
      final result = defaults.copyWith(
        fontSize: 22.0,
        font: DyslexiaFont.arial,
        rulerEnabled: false,
      );
      expect(result.fontSize, 22.0);
      expect(result.font, DyslexiaFont.arial);
      expect(result.rulerEnabled, false);
      // Other fields unchanged
      expect(result.lineSpacing, defaults.lineSpacing);
      expect(result.colorTheme, defaults.colorTheme);
    });
  });
}
