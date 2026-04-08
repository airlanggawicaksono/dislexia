import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_url.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/login_model.dart';
import '../models/register_model.dart';
import '../models/user_model.dart';

sealed class AuthRemoteDataSource {
  Future<UserModel> login(LoginModel model);
  Future<void> logout();
  Future<void> register(RegisterModel model);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(LoginModel model) async {
    try {
      final user = await _getUserByEmail(model.email ?? "");
      return user;
    } on EmptyException {
      throw AuthException();
    } catch (e) {
      logger.e(e);
      throw ServerException();
    }
  }

  @override
  Future<void> logout() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    } catch (e) {
      logger.e(e);
      throw ServerException();
    }
  }

  @override
  Future<void> register(RegisterModel model) async {
    try {
      final box = await Hive.openBox<Map>(ApiUrl.usersBox);
      final existing = box.get(model.email);
      if (existing != null) {
        throw DuplicateEmailException();
      }
      final userId = const Uuid().v4();
      await box.put(model.email, {
        "user_id": userId,
        "email": model.email,
        "username": model.username,
        "password": model.password,
      });
      return;
    } on DuplicateEmailException {
      rethrow;
    } catch (e) {
      logger.e(e);
      throw ServerException();
    }
  }

  Future<UserModel> _getUserByEmail(String email) async {
    try {
      final box = await Hive.openBox<Map>(ApiUrl.usersBox);
      final data = box.get(email);
      if (data == null) throw EmptyException();
      final map = Map<String, dynamic>.from(data);
      return UserModel.fromJson(map, map["user_id"] ?? "");
    } on EmptyException {
      rethrow;
    } catch (e) {
      logger.e(e);
      throw ServerException();
    }
  }
}
