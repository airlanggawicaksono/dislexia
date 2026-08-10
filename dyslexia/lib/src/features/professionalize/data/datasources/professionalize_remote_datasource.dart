import '../../../../core/api/api_client.dart';
import '../models/professionalize_model.dart';

abstract class ProfessionalizeRemoteDatasource {
  /// Stream the rewritten text as it is generated (SSE over
  /// `/process-stream`). Emits each chunk's text content; errors surface as
  /// a stream error.
  Stream<String> professionalizeStream(ProfessionalizeRequestModel request);
}

class ProfessionalizeRemoteDatasourceImpl implements ProfessionalizeRemoteDatasource {
  final ApiClient _api;
  const ProfessionalizeRemoteDatasourceImpl(this._api);

  @override
  Stream<String> professionalizeStream(ProfessionalizeRequestModel request) =>
      _api.postStream(
          '/me/professionalize/process-stream', body: request.toJson());
}
