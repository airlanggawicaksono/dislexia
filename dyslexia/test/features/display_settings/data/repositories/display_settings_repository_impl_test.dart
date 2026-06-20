import 'package:dyslexia/src/features/display_settings/data/datasources/display_settings_local_datasource.dart';
import 'package:dyslexia/src/features/display_settings/data/models/display_settings_model.dart';
import 'package:dyslexia/src/features/display_settings/data/repositories/display_settings_repository_impl.dart';
import 'package:dyslexia/src/features/display_settings/domain/entities/display_settings_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatasource extends Mock implements DisplaySettingsLocalDatasource {}

void main() {
  late MockDatasource mockDatasource;
  late DisplaySettingsRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockDatasource();
    repository = DisplaySettingsRepositoryImpl(mockDatasource);
  });

  group('load', () {
    test('returns defaults when datasource returns empty map', () async {
      when(() => mockDatasource.load()).thenAnswer((_) async => {});

      final result = await repository.load();

      expect(result, equals(DisplaySettingsModel.defaults()));
    });

    test('returns parsed model from datasource map', () async {
      const expected = DisplaySettingsModel(
        fontSize: 22.0,
        lineSpacing: 2.0,
        letterSpacing: 0.5,
        wordSpacing: 4.0,
        font: DyslexiaFont.openDyslexic,
        colorTheme: AppColorTheme.cream,
        preset: DisplayPreset.defaultPreset,
        rulerEnabled: true,
        syllablesEnabled: true,
      );
      when(() => mockDatasource.load()).thenAnswer((_) async => expected.toMap());

      final result = await repository.load();

      expect(result, equals(expected));
    });
  });

  group('save', () {
    test('saves DisplaySettingsModel via datasource', () async {
      final settings = DisplaySettingsModel.defaults().copyWith(fontSize: 24.0);
      when(() => mockDatasource.save(any())).thenAnswer((_) async {});

      await repository.save(settings);

      verify(() => mockDatasource.save(settings.toMap())).called(1);
    });

    test('saves plain DisplaySettingsEntity by converting to model first', () async {
      final entity = DisplaySettingsEntity(
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
      when(() => mockDatasource.save(any())).thenAnswer((_) async {});

      await repository.save(entity);

      final expectedMap = DisplaySettingsModel(
        fontSize: entity.fontSize,
        lineSpacing: entity.lineSpacing,
        letterSpacing: entity.letterSpacing,
        wordSpacing: entity.wordSpacing,
        font: entity.font,
        colorTheme: entity.colorTheme,
        preset: entity.preset,
        rulerEnabled: entity.rulerEnabled,
        syllablesEnabled: entity.syllablesEnabled,
      ).toMap();
      verify(() => mockDatasource.save(expectedMap)).called(1);
    });
  });
}
