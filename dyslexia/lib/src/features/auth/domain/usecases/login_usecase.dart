import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  final String accountNumber;
  const LoginParams(this.accountNumber);

  @override
  List<Object?> get props => [accountNumber];
}

/// `POST /api/v1/auth/login` — takes a 6-digit account number and
/// returns a fresh access token + user profile. Validates the input
/// shape locally before hitting the network.
class LoginUseCase implements UseCase<AuthSessionEntity, LoginParams> {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  @override
  Future<Either<Failure, AuthSessionEntity>> call(LoginParams params) {
    final cleaned = params.accountNumber.trim();
    if (cleaned.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleaned)) {
      return Future.value(const Left(InvalidAccountNumberFailure()));
    }
    return _repository.login(cleaned);
  }
}
