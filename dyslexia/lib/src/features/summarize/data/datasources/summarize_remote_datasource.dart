import '../../../../core/api/api_client.dart';
import '../models/summarize_model.dart';

abstract class SummarizeRemoteDatasource {
  /// Stream the summary as it is generated (SSE over `/process-stream`).
  /// Emits each chunk's text content; errors surface as a stream error.
  Stream<String> summarizeStream(SummarizeRequestModel request);
}

class SummarizeRemoteDatasourceImpl implements SummarizeRemoteDatasource {
  final ApiClient _api;
  const SummarizeRemoteDatasourceImpl(this._api);

  @override
  Stream<String> summarizeStream(SummarizeRequestModel request) =>
      _api.postStream('/me/summarize/process-stream', body: request.toJson());
}
