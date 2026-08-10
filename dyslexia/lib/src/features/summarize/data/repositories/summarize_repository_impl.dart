import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api_exception.dart';
import '../datasources/summarize_remote_datasource.dart';
import '../models/summarize_model.dart';
import '../../domain/entities/summary_level.dart';
import '../../domain/repositories/summarize_repository.dart';

class SummarizeRepositoryImpl implements SummarizeRepository {
  final SummarizeRemoteDatasource _remote;
  const SummarizeRepositoryImpl(this._remote);

  @override
  Stream<Either<Failure, String>> summarizeStream(
    String text, {
    SummaryLevel? level,
  }) async* {
    try {
      await for (final chunk in _remote.summarizeStream(
        SummarizeRequestModel(text: text, level: level),
      )) {
        yield right(chunk);
      }
    } on ApiException catch (e) {
      yield left(ServerFailureWithMessage(e.message));
    } catch (_) {
      yield left(const ServerFailure());
    }
  }
}

class ServerFailureWithMessage extends Failure {
  final String message;
  const ServerFailureWithMessage(this.message);

  @override
  List<Object> get props => [message];
}
