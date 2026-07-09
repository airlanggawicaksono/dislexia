import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/api/api_client.dart';
import '../models/auth_session_model.dart';

abstract class AuthRemoteDatasource {
  Future<AuthSessionModel> login(String accountNumber);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient _api;
  const AuthRemoteDatasourceImpl(this._api);

  @override
  Future<AuthSessionModel> login(String accountNumber) {
    final cleaned = accountNumber.replaceAll(RegExp(r'\s+'), '');
    // Native (non-web) clients opt into an effectively-permanent session so
    // users stay signed in. The web build omits the header and keeps the
    // default short-lived token — same codebase, different lifetime.
    return _api.postObject(
      '/auth/login',
      body: {'account_number': cleaned},
      headers: kIsWeb ? null : const {'X-Long-Session': 'true'},
      parse: AuthSessionModel.fromJson,
    );
  }
}
