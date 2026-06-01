import '../../domain/entities/generated_account_entity.dart';

class GeneratedAccountModel extends GeneratedAccountEntity {
  const GeneratedAccountModel({
    required super.accountNumber,
    required super.displayName,
    required super.accessToken,
    required super.tokenType,
    required super.expiresIn,
  });

  factory GeneratedAccountModel.fromJson(Map<String, dynamic> json) {
    return GeneratedAccountModel(
      accountNumber: json['account_number']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
    );
  }
}
