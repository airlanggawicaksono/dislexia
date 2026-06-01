import 'package:equatable/equatable.dart';

/// Result of `POST /auth/generate`: the freshly minted account number
/// (the only credential the user keeps) plus the initial access token
/// that lets them start using the API right away.
class GeneratedAccountEntity extends Equatable {
  final String accountNumber;
  final String displayName;
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  const GeneratedAccountEntity({
    required this.accountNumber,
    required this.displayName,
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  @override
  List<Object?> get props =>
      [accountNumber, displayName, accessToken, tokenType, expiresIn];
}
