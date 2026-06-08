import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/screening_result.dart';
import '../repositories/screening_repository.dart';

class ScreeningUseCase {
  final ScreeningRepository _repository;
  const ScreeningUseCase(this._repository);

  Future<Either<Failure, ScreeningResult>> start() => _repository.start();

  Future<Either<Failure, ScreeningResult>> reply(
          String text, String sessionId) =>
      _repository.reply(text, sessionId);
}
