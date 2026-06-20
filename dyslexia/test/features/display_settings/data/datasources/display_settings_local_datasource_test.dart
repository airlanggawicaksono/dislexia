import 'package:dyslexia/src/core/cache/local_storage.dart';
import 'package:dyslexia/src/features/display_settings/data/datasources/display_settings_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  late MockLocalStorage mockStorage;
  late DisplaySettingsLocalDatasource datasource;

  setUp(() {
    mockStorage = MockLocalStorage();
    datasource = DisplaySettingsLocalDatasource(mockStorage);
  });

  group('load', () {
    test('returns empty map when storage returns null', () async {
      when(() => mockStorage.load(key: any(named: 'key'), boxName: any(named: 'boxName')))
          .thenAnswer((_) async => null);

      final result = await datasource.load();

      expect(result, {});
      verify(() => mockStorage.load(key: 'settings', boxName: 'display_settings')).called(1);
    });

    test('returns empty map when storage returns non-Map', () async {
      when(() => mockStorage.load(key: any(named: 'key'), boxName: any(named: 'boxName')))
          .thenAnswer((_) async => 'not a map');

      final result = await datasource.load();

      expect(result, {});
    });

    test('returns the stored map when valid', () async {
      final storedData = {'fontSize': 20.0, 'font': 1};
      when(() => mockStorage.load(key: any(named: 'key'), boxName: any(named: 'boxName')))
          .thenAnswer((_) async => storedData);

      final result = await datasource.load();

      expect(result, storedData);
    });
  });

  group('save', () {
    test('delegates to storage with correct key and boxName', () async {
      final data = {'fontSize': 22.0};
      when(() => mockStorage.save(
            key: any(named: 'key'),
            value: any(named: 'value'),
            boxName: any(named: 'boxName'),
          )).thenAnswer((_) async {});

      await datasource.save(data);

      verify(() => mockStorage.save(
            key: 'settings',
            value: data,
            boxName: 'display_settings',
          )).called(1);
    });
  });
}
