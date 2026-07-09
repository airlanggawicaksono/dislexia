import '../../../../core/api/api_client.dart';
import '../models/define_model.dart';

abstract class DefineRemoteDatasource {
  Future<DefineResponseModel> define(DefineRequestModel request);
}

class DefineRemoteDatasourceImpl implements DefineRemoteDatasource {
  final ApiClient _api;
  const DefineRemoteDatasourceImpl(this._api);

  @override
  Future<DefineResponseModel> define(DefineRequestModel request) {
    return _api.postObject(
      '/me/define/process',
      body: request.toJson(),
      parse: DefineResponseModel.fromJson,
    );
  }
}
