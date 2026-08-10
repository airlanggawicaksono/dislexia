import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api_exception.dart';
import '../datasources/define_remote_datasource.dart';
import '../models/define_model.dart';
import '../../domain/entities/define_level.dart';
import '../../domain/repositories/define_repository.dart';

class DefineRepositoryImpl implements DefineRepository {
  final DefineRemoteDatasource _remote;
  const DefineRepositoryImpl(this._remote);

  @override
  Stream<Either<Failure, String>> defineStream(
    String text, {
    DefineLevel? level,
  }) async* {
    try {
      await for (final chunk in _remote.defineStream(
        DefineRequestModel(text: text, level: level),
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
