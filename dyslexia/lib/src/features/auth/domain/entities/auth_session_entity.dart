import 'package:equatable/equatable.dart';

import 'auth_user_entity.dart';

/// A logged-in session: access token + associated user profile.
class AuthSessionEntity extends Equatable {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final AuthUserEntity user;

  const AuthSessionEntity({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  @override
  List<Object?> get props => [accessToken, tokenType, expiresIn, user];
}
