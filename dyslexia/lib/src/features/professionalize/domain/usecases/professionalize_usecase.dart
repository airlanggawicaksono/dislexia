import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/professionalize_repository.dart';

class ProfessionalizeUseCase {
  final ProfessionalizeRepository _repository;
  const ProfessionalizeUseCase(this._repository);

  Stream<Either<Failure, String>> call(
    String text, {
    String? recipientName,
    String? senderName,
  }) =>
      _repository.professionalizeStream(
        text,
        recipientName: recipientName,
        senderName: senderName,
      );
}
