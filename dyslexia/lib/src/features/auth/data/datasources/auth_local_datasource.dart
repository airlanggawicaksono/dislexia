import 'dart:convert';

import '../../../../core/cache/secure_local_storage.dart';
import '../models/auth_session_model.dart';

/// Persists the active session (access token + user profile) in
/// [SecureLocalStorage]. The blob is stored as a single JSON string
/// under [_storageKey] so the rest of the app only ever needs one
/// read/write per restore/login/logout cycle.
abstract class AuthLocalDatasource {
  Future<AuthSessionModel?> readSession();
  Future<void> writeSession(AuthSessionModel session);
  Future<void> clearSession();
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  static const _storageKey = 'dyslexia.auth.session';

  final SecureLocalStorage _storage;
  const AuthLocalDatasourceImpl(this._storage);

  @override
  Future<AuthSessionModel?> readSession() async {
    final raw = await _storage.load(key: _storageKey);
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AuthSessionModel.fromStoredJson(decoded);
    } catch (_) {
      // Corrupt / older schema — wipe and behave as logged out.
      await _storage.delete(key: _storageKey);
      return null;
    }
  }

  @override
  Future<void> writeSession(AuthSessionModel session) async {
    await _storage.save(
      key: _storageKey,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _storageKey);
  }
}
