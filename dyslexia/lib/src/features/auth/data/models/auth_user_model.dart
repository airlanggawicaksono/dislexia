import '../../domain/entities/auth_user_entity.dart';

class AuthUserModel extends AuthUserEntity {
  const AuthUserModel({
    required super.userId,
    required super.accountNumber,
    required super.displayName,
    super.createdAt,
    super.lastLogin,
    super.isActive,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return AuthUserModel(
      userId: json['user_id']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      createdAt: parseDate(json['created_at']),
      lastLogin: parseDate(json['last_login']),
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : true,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'account_number': accountNumber,
        'display_name': displayName,
        'created_at': createdAt?.toIso8601String(),
        'last_login': lastLogin?.toIso8601String(),
        'is_active': isActive,
      };
}
