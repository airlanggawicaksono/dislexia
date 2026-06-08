import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api_exception.dart';
import '../datasources/screening_remote_datasource.dart';
import '../models/screening_model.dart';
import '../../domain/entities/screening_result.dart';
import '../../domain/repositories/screening_repository.dart';

class ScreeningRepositoryImpl implements ScreeningRepository {
  final ScreeningRemoteDatasource _remote;
  const ScreeningRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, ScreeningResult>> start() async {
    try {
      final res = await _remote.start();
      return right(ScreeningResult(
        text: res.result,
        sessionId: res.sessionId,
        historyId: res.historyId,
        isComplete: res.isComplete,
      ));
    } on ApiException catch (e) {
      return left(ServerFailureWithMessage(e.message));
    } catch (_) {
      return left(const ServerFailure());
    }
  }

  @override
  Future<Either<Failure, ScreeningResult>> reply(
      String text, String sessionId) async {
    try {
      final res = await _remote.reply(
        ScreeningReplyRequestModel(text: text, sessionId: sessionId),
      );
      return right(ScreeningResult(
        text: res.result,
        sessionId: res.sessionId,
        historyId: res.historyId,
        isComplete: res.isComplete,
      ));
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
