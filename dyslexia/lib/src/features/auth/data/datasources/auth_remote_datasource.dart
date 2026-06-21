import '../../../../core/api/api_helper.dart';
import '../../../../core/api/api_url.dart';
import '../models/auth_session_model.dart';

abstract class AuthRemoteDatasource {
  Future<AuthSessionModel> login(String accountNumber);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiHelper _api;
  const AuthRemoteDatasourceImpl(this._api);

  @override
  Future<AuthSessionModel> login(String accountNumber) async {
    final cleaned = accountNumber.replaceAll(RegExp(r'\s+'), '');
    final res = await _api.execute(
      method: Method.post,
      url: '${ApiUrl.baseUrl}/auth/login',
      data: {'account_number': cleaned},
    );
    return AuthSessionModel.fromJson(res);
  }
}
