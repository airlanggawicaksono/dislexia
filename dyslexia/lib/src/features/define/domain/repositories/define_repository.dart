import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/define_level.dart';
import '../entities/define_result.dart';

abstract class DefineRepository {
  Future<Either<Failure, DefineResult>> define(String text, {DefineLevel? level});
}
