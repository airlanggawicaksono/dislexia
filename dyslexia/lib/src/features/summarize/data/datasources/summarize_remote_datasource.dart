import '../../../../core/api/api_helper.dart';
import '../../../../core/api/api_url.dart';
import '../models/summarize_model.dart';

abstract class SummarizeRemoteDatasource {
  Future<SummarizeResponseModel> summarize(SummarizeRequestModel request);
}

class SummarizeRemoteDatasourceImpl implements SummarizeRemoteDatasource {
  final ApiHelper _api;
  const SummarizeRemoteDatasourceImpl(this._api);

  @override
  Future<SummarizeResponseModel> summarize(SummarizeRequestModel request) async {
    final res = await _api.execute(
      method: Method.post,
      url: '${ApiUrl.baseUrl}/me/summarize/process',
      data: request.toJson(),
    );
    return SummarizeResponseModel.fromJson(res);
  }
}
