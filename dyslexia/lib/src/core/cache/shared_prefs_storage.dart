import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage.dart';

/// A [LocalStorage] implementation backed by [SharedPreferences].
///
/// Wasm-compatible — uses `package:web` under the hood (via
/// shared_preferences 2.3+) instead of `dart:html`. The [boxName] is
/// used as a key prefix to namespace entries. All values are
/// JSON-encoded so structured data (Maps, Lists) round-trips
/// correctly.
class SharedPrefsLocalStorage implements LocalStorage {
  @override
  Future<dynamic> load({required String key, String? boxName}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(key, boxName));
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  @override
  Future<void> save({
    required String key,
    required dynamic value,
    String? boxName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(key, boxName), jsonEncode(value));
  }

  @override
  Future<void> delete({required String key, String? boxName}) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _storageKey(key, boxName);
    await prefs.remove(storageKey);
  }

  String _storageKey(String key, String? boxName) =>
      boxName != null ? '$boxName.$key' : key;
}
