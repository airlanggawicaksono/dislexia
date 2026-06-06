import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/personalize_result.dart';

abstract class PersonalizeRepository {
  Future<Either<Failure, PersonalizeResult>> personalize(String text);
}
