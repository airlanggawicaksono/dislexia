import '../../../../core/api/api_helper.dart';
import '../../../../core/api/api_url.dart';
import '../models/screening_model.dart';

abstract class ScreeningRemoteDatasource {
  Future<ScreeningResponseModel> start();
  Future<ScreeningResponseModel> reply(ScreeningReplyRequestModel request);
}

class ScreeningRemoteDatasourceImpl implements ScreeningRemoteDatasource {
  final ApiHelper _api;
  const ScreeningRemoteDatasourceImpl(this._api);

  @override
  Future<ScreeningResponseModel> start() async {
    final res = await _api.execute(
      method: Method.post,
      url: '${ApiUrl.baseUrl}/me/screen/start',
    );
    return ScreeningResponseModel.fromJson(res);
  }

  @override
  Future<ScreeningResponseModel> reply(ScreeningReplyRequestModel request) async {
    final res = await _api.execute(
      method: Method.post,
      url: '${ApiUrl.baseUrl}/me/screen/reply',
      data: request.toJson(),
    );
    return ScreeningResponseModel.fromJson(res);
  }
}
