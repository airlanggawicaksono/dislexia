import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/professionalize_result.dart';

abstract class ProfessionalizeRepository {
  Future<Either<Failure, ProfessionalizeResult>> professionalize(String text);
}
