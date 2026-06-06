import '../../../../core/api/api_helper.dart';
import '../../../../core/api/api_url.dart';
import '../models/define_model.dart';

abstract class DefineRemoteDatasource {
  Future<DefineResponseModel> define(DefineRequestModel request);
}

class DefineRemoteDatasourceImpl implements DefineRemoteDatasource {
  final ApiHelper _api;
  const DefineRemoteDatasourceImpl(this._api);

  @override
  Future<DefineResponseModel> define(DefineRequestModel request) async {
    final res = await _api.execute(
      method: Method.post,
      url: '${ApiUrl.baseUrl}/me/define/process',
      data: request.toJson(),
    );
    return DefineResponseModel.fromJson(res);
  }
}
