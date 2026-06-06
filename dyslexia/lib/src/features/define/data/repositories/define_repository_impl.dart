import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api_exception.dart';
import '../datasources/define_remote_datasource.dart';
import '../models/define_model.dart';
import '../../domain/entities/define_result.dart';
import '../../domain/repositories/define_repository.dart';

class DefineRepositoryImpl implements DefineRepository {
  final DefineRemoteDatasource _remote;
  const DefineRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, DefineResult>> define(String text) async {
    try {
      final res = await _remote.define(
        DefineRequestModel(text: text),
      );
      return right(DefineResult(text: res.result, sessionId: res.sessionId));
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
