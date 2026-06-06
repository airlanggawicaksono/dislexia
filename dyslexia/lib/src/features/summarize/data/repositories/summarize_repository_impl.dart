import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api_exception.dart';
import '../datasources/summarize_remote_datasource.dart';
import '../models/summarize_model.dart';
import '../../domain/entities/summarize_result.dart';
import '../../domain/repositories/summarize_repository.dart';

class SummarizeRepositoryImpl implements SummarizeRepository {
  final SummarizeRemoteDatasource _remote;
  const SummarizeRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, SummarizeResult>> summarize(String text) async {
    try {
      final res = await _remote.summarize(
        SummarizeRequestModel(text: text),
      );
      return right(SummarizeResult(text: res.result, sessionId: res.sessionId));
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
