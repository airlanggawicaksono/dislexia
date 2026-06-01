import '../../domain/entities/auth_session_entity.dart';
import 'auth_user_model.dart' show AuthUserModel;

class AuthSessionModel extends AuthSessionEntity {
  const AuthSessionModel({
    required super.accessToken,
    required super.tokenType,
    required super.expiresIn,
    required super.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return AuthSessionModel(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      user: userJson is Map<String, dynamic>
          ? AuthUserModel.fromJson(userJson)
          : AuthUserModel(
              userId: '',
              accountNumber: '',
              displayName: '',
            ),
    );
  }

  factory AuthSessionModel.fromStoredJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return AuthSessionModel(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      user: userJson is Map<String, dynamic>
          ? AuthUserModel.fromJson(userJson)
          : AuthUserModel(
              userId: '',
              accountNumber: '',
              displayName: '',
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'token_type': tokenType,
        'expires_in': expiresIn,
        'user': (user is AuthUserModel)
            ? (user as AuthUserModel).toJson()
            : {
                'user_id': user.userId,
                'account_number': user.accountNumber,
                'display_name': user.displayName,
                'created_at': user.createdAt?.toIso8601String(),
                'last_login': user.lastLogin?.toIso8601String(),
                'is_active': user.isActive,
              },
      };
}
