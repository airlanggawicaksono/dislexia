import '../../../../core/api/api_client.dart';
import '../models/summarize_model.dart';

abstract class SummarizeRemoteDatasource {
  Future<SummarizeResponseModel> summarize(SummarizeRequestModel request);
}

class SummarizeRemoteDatasourceImpl implements SummarizeRemoteDatasource {
  final ApiClient _api;
  const SummarizeRemoteDatasourceImpl(this._api);

  @override
  Future<SummarizeResponseModel> summarize(SummarizeRequestModel request) {
    return _api.postObject(
      '/me/summarize/process',
      body: request.toJson(),
      parse: SummarizeResponseModel.fromJson,
    );
  }
}
