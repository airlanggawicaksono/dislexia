import '../../../../core/cache/local_storage.dart';

const _boxName = 'display_settings';
const _key = 'settings';

class DisplaySettingsLocalDatasource {
  final LocalStorage _storage;

  const DisplaySettingsLocalDatasource(this._storage);

  Future<Map<String, dynamic>> load() async {
    final data = await _storage.load(key: _key, boxName: _boxName);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<void> save(Map<String, dynamic> data) async {
    await _storage.save(key: _key, value: data, boxName: _boxName);
  }
}
