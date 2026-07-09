import '../../../../core/api/api_client.dart';
import '../models/professionalize_model.dart';

abstract class ProfessionalizeRemoteDatasource {
  Future<ProfessionalizeResponseModel> professionalize(ProfessionalizeRequestModel request);
}

class ProfessionalizeRemoteDatasourceImpl implements ProfessionalizeRemoteDatasource {
  final ApiClient _api;
  const ProfessionalizeRemoteDatasourceImpl(this._api);

  @override
  Future<ProfessionalizeResponseModel> professionalize(ProfessionalizeRequestModel request) {
    return _api.postObject(
      '/me/professionalize/process',
      body: request.toJson(),
      parse: ProfessionalizeResponseModel.fromJson,
    );
  }
}
