import 'package:dyslexia/src/features/display_settings/data/models/display_settings_model.dart';
import 'package:dyslexia/src/features/display_settings/domain/entities/display_settings_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DisplaySettingsModel.defaults', () {
    test('creates a model with default values', () {
      final model = DisplaySettingsModel.defaults();
      expect(model.fontSize, 18.0);
      expect(model.lineSpacing, 1.5);
      expect(model.letterSpacing, 0.5);
      expect(model.wordSpacing, 4.0);
      expect(model.font, DyslexiaFont.openDyslexic);
      expect(model.colorTheme, AppColorTheme.cream);
      expect(model.preset, DisplayPreset.defaultPreset);
      expect(model.rulerEnabled, true);
      expect(model.syllablesEnabled, true);
    });
  });

  group('toMap / fromMap round-trip', () {
    test('round-trips default values', () {
      final original = DisplaySettingsModel.defaults();
      final map = original.toMap();
      final restored = DisplaySettingsModel.fromMap(map);
      expect(restored, equals(original));
    });

    test('round-trips custom values', () {
      final original = DisplaySettingsModel(
        fontSize: 24.0,
        lineSpacing: 2.5,
        letterSpacing: 1.0,
        wordSpacing: 6.0,
        font: DyslexiaFont.arial,
        colorTheme: AppColorTheme.dark,
        preset: DisplayPreset.highContrast,
        rulerEnabled: false,
        syllablesEnabled: false,
      );
      final map = original.toMap();
      final restored = DisplaySettingsModel.fromMap(map);
      expect(restored, equals(original));
    });

    test('handles missing keys with defaults', () {
      final restored = DisplaySettingsModel.fromMap({});
      expect(restored.fontSize, 18.0);
      expect(restored.lineSpacing, 1.5);
      expect(restored.letterSpacing, 0.5);
      expect(restored.wordSpacing, 4.0);
      expect(restored.font, DyslexiaFont.openDyslexic);
      expect(restored.colorTheme, AppColorTheme.cream);
      expect(restored.preset, DisplayPreset.defaultPreset);
      expect(restored.rulerEnabled, true);
      expect(restored.syllablesEnabled, true);
    });

    test('handles null numeric values with defaults', () {
      final restored = DisplaySettingsModel.fromMap({
        'fontSize': null,
        'lineSpacing': null,
        'letterSpacing': null,
        'wordSpacing': null,
      });
      expect(restored.fontSize, 18.0);
      expect(restored.lineSpacing, 1.5);
    });

    test('clamps out-of-range enum indexes', () {
      final restored = DisplaySettingsModel.fromMap({
        'font': 999,
        'colorTheme': -1,
        'preset': 999,
      });
      expect(restored.font, DyslexiaFont.values.last);
      expect(restored.colorTheme, AppColorTheme.values.first);
      expect(restored.preset, DisplayPreset.values.last);
    });
  });

  group('copyWith', () {
    test('inherits copyWith from entity and returns DisplaySettingsModel', () {
      final model = DisplaySettingsModel.defaults().copyWith(fontSize: 20.0);
      expect(model, isA<DisplaySettingsModel>());
      expect(model.fontSize, 20.0);
    });
  });
}
