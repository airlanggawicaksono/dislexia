import '../../../../core/api/api_client.dart';
import '../models/define_model.dart';

abstract class DefineRemoteDatasource {
  /// Stream the definition as it is generated (SSE over `/process-stream`).
  /// Emits each chunk's text content; errors surface as a stream error.
  Stream<String> defineStream(DefineRequestModel request);
}

class DefineRemoteDatasourceImpl implements DefineRemoteDatasource {
  final ApiClient _api;
  const DefineRemoteDatasourceImpl(this._api);

  @override
  Stream<String> defineStream(DefineRequestModel request) =>
      _api.postStream('/me/define/process-stream', body: request.toJson());
}
