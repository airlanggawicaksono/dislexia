import 'package:dio/dio.dart';

import '../../../../core/api/api_helper.dart';
import '../../../../core/api/api_url.dart';
import '../models/auth_session_model.dart';
import '../models/generated_account_model.dart';

abstract class AuthRemoteDatasource {
  Future<GeneratedAccountModel> generateAccount();
  Future<AuthSessionModel> login(String accountNumber);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiHelper _api;
  const AuthRemoteDatasourceImpl(this._api);

  @override
  Future<GeneratedAccountModel> generateAccount() async {
    final res = await _api.execute(
      method: Method.post,
      url: '${ApiUrl.baseUrl}/auth/generate',
    );
    return GeneratedAccountModel.fromJson(res);
  }

  @override
  Future<AuthSessionModel> login(String accountNumber) async {
    final res = await _api.execute(
      method: Method.post,
      url: '${ApiUrl.baseUrl}/auth/login',
      data: {'account_number': accountNumber},
    );
    return AuthSessionModel.fromJson(res);
  }
}
