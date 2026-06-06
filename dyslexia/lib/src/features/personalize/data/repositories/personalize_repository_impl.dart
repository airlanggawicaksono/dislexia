import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api_exception.dart';
import '../datasources/personalize_remote_datasource.dart';
import '../models/personalize_model.dart';
import '../../domain/entities/personalize_result.dart';
import '../../domain/repositories/personalize_repository.dart';

class PersonalizeRepositoryImpl implements PersonalizeRepository {
  final PersonalizeRemoteDatasource _remote;
  const PersonalizeRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PersonalizeResult>> personalize(String text) async {
    try {
      final res = await _remote.personalize(
        PersonalizeRequestModel(text: text),
      );
      return right(PersonalizeResult(text: res.result, sessionId: res.sessionId));
    } on ApiException catch (e) {
      return left(ServerFailureWithMessage(e.message));
    } catch (_) {
      return left(const ServerFailure());
    }
  }
}

class ServerFailureWithMessage extends Failure {
  final String message;
  const ServerFailureWithMessage(this.message);

  @override
  List<Object> get props => [message];
}
