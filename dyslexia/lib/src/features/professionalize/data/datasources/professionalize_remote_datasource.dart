import '../../../../core/api/api_helper.dart';
import '../../../../core/api/api_url.dart';
import '../models/professionalize_model.dart';

abstract class ProfessionalizeRemoteDatasource {
  Future<ProfessionalizeResponseModel> professionalize(ProfessionalizeRequestModel request);
}

class ProfessionalizeRemoteDatasourceImpl implements ProfessionalizeRemoteDatasource {
  final ApiHelper _api;
  const ProfessionalizeRemoteDatasourceImpl(this._api);

  @override
  Future<ProfessionalizeResponseModel> professionalize(ProfessionalizeRequestModel request) async {
    final res = await _api.execute(
      method: Method.post,
      url: '${ApiUrl.baseUrl}/me/professionalize/process',
      data: request.toJson(),
    );
    return ProfessionalizeResponseModel.fromJson(res);
  }
}
