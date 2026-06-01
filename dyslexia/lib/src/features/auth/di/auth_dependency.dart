import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api/api_helper.dart';
import '../../../core/api/api_interceptor.dart';
import '../../../core/cache/secure_local_storage.dart';
import '../../../configs/injector/injector_conf.dart';
import '../data/datasources/auth_local_datasource.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/generate_account_usecase.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../domain/usecases/restore_session_usecase.dart';
import '../presentation/bloc/auth/auth_bloc.dart';

class AuthDependency {
  AuthDependency._();

  static void init() {
    // ---- infrastructure the auth feature needs ------------------
    if (!getIt.isRegistered<FlutterSecureStorage>()) {
      getIt.registerLazySingleton<FlutterSecureStorage>(
        () => const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ),
      );
    }
    if (!getIt.isRegistered<SecureLocalStorage>()) {
      getIt.registerLazySingleton<SecureLocalStorage>(
        () => SecureLocalStorage(getIt<FlutterSecureStorage>()),
      );
    }
    if (!getIt.isRegistered<ApiHelper>()) {
      final dio = Dio()..interceptors.add(ApiInterceptor());
      getIt.registerLazySingleton<ApiHelper>(() => ApiHelper(dio));
    }

    // ---- auth data layer ----------------------------------------
    getIt.registerLazySingleton<AuthLocalDatasource>(
      () => AuthLocalDatasourceImpl(getIt<SecureLocalStorage>()),
    );
    getIt.registerLazySingleton<AuthRemoteDatasource>(
      () => AuthRemoteDatasourceImpl(getIt<ApiHelper>()),
    );
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: getIt<AuthRemoteDatasource>(),
        local: getIt<AuthLocalDatasource>(),
      ),
    );

    // ---- auth use cases -----------------------------------------
    getIt.registerLazySingleton(
      () => GenerateAccountUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(
      () => LoginUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(
      () => LogoutUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(
      () => RestoreSessionUseCase(getIt<AuthRepository>()),
    );

    // ---- auth BLoC (factory — fresh bloc per BlocProvider) ------
    getIt.registerFactory<AuthBloc>(
      () => AuthBloc(
        generateAccount: getIt<GenerateAccountUseCase>(),
        login: getIt<LoginUseCase>(),
        logout: getIt<LogoutUseCase>(),
        restoreSession: getIt<RestoreSessionUseCase>(),
      ),
    );
  }
}
