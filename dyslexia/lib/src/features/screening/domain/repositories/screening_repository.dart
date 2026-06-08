import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/screening_result.dart';

abstract class ScreeningRepository {
  Future<Either<Failure, ScreeningResult>> start();
  Future<Either<Failure, ScreeningResult>> reply(String text, String sessionId);
}
