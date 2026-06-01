import 'package:equatable/equatable.dart';

/// Authenticated user profile. Mirrors the backend `UserResponseDTO`.
class AuthUserEntity extends Equatable {
  final String userId;
  final String accountNumber;
  final String displayName;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool isActive;

  const AuthUserEntity({
    required this.userId,
    required this.accountNumber,
    required this.displayName,
    this.createdAt,
    this.lastLogin,
    this.isActive = true,
  });

  @override
  List<Object?> get props =>
      [userId, accountNumber, displayName, createdAt, lastLogin, isActive];
}
