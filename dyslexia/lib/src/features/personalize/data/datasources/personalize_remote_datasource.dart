import '../../../../core/api/api_helper.dart';
import '../../../../core/api/api_url.dart';
import '../models/personalize_model.dart';

abstract class PersonalizeRemoteDatasource {
  Future<PersonalizeResponseModel> personalize(PersonalizeRequestModel request);
}

class PersonalizeRemoteDatasourceImpl implements PersonalizeRemoteDatasource {
  final ApiHelper _api;
  const PersonalizeRemoteDatasourceImpl(this._api);

  @override
  Future<PersonalizeResponseModel> personalize(PersonalizeRequestModel request) async {
    final res = await _api.execute(
      method: Method.post,
      url: '${ApiUrl.baseUrl}/me/professionalize/process',
      data: request.toJson(),
    );
    return PersonalizeResponseModel.fromJson(res);
  }
}
