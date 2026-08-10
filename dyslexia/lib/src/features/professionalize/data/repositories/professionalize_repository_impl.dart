import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/api/api_exception.dart';
import '../datasources/professionalize_remote_datasource.dart';
import '../models/professionalize_model.dart';
import '../../domain/repositories/professionalize_repository.dart';

class ProfessionalizeRepositoryImpl implements ProfessionalizeRepository {
  final ProfessionalizeRemoteDatasource _remote;
  const ProfessionalizeRepositoryImpl(this._remote);

  @override
  Stream<Either<Failure, String>> professionalizeStream(
    String text, {
    String? recipientName,
    String? senderName,
  }) async* {
    try {
      await for (final chunk in _remote.professionalizeStream(
        ProfessionalizeRequestModel(
          text: text,
          recipientName: recipientName,
          senderName: senderName,
        ),
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
