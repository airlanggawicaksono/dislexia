import '../../../../core/api/api_client.dart';
import '../models/screening_model.dart';

abstract class ScreeningRemoteDatasource {
  Future<ScreeningResponseModel> start();
  Future<ScreeningResponseModel> reply(ScreeningReplyRequestModel request);
}

class ScreeningRemoteDatasourceImpl implements ScreeningRemoteDatasource {
  final ApiClient _api;
  const ScreeningRemoteDatasourceImpl(this._api);

  @override
  Future<ScreeningResponseModel> start() {
    return _api.postObject(
      '/me/screen/start',
      parse: ScreeningResponseModel.fromJson,
    );
  }

  @override
  Future<ScreeningResponseModel> reply(ScreeningReplyRequestModel request) {
    return _api.postObject(
      '/me/screen/reply',
      body: request.toJson(),
      parse: ScreeningResponseModel.fromJson,
    );
  }
}
