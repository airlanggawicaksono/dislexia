import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api_exception.dart';
import '../datasources/professionalize_remote_datasource.dart';
import '../models/professionalize_model.dart';
import '../../domain/entities/professionalize_result.dart';
import '../../domain/repositories/professionalize_repository.dart';

class ProfessionalizeRepositoryImpl implements ProfessionalizeRepository {
  final ProfessionalizeRemoteDatasource _remote;
  const ProfessionalizeRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, ProfessionalizeResult>> professionalize(String text) async {
    try {
      final res = await _remote.professionalize(
        ProfessionalizeRequestModel(text: text),
      );
      return right(ProfessionalizeResult(text: res.result, sessionId: res.sessionId));
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
