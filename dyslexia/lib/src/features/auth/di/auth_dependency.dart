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
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../domain/usecases/restore_session_usecase.dart';
import '../presentation/bloc/auth/auth_bloc.dart';
import '../presentation/bloc/logout_bus.dart';
import '../presentation/bloc/token_holder.dart';

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

    // Build the single Dio instance the whole app shares. It carries
    // an [AuthInterceptor] that:
    //
    //   * reads the *current* bearer token from [TokenHolder] on every
    //     outgoing request (Dio interceptor hooks are synchronous), and
    //   * on a 401 response, fires [LogoutBus] so the AuthBloc can
    //     transition the UI back to the login screen.
    //
    // The bootstrap auth endpoints (`/auth/generate`, `/auth/login`)
    // are excluded from both behaviours so the very first call works
    // and a bad-credentials 401 is not interpreted as "session died".
    if (!getIt.isRegistered<ApiHelper>()) {
      final dio = Dio()
        ..interceptors.add(
          AuthInterceptor(
            tokenProvider: () => TokenHolder.instance.token,
            onUnauthorized: (_) => LogoutBus.fire(),
          ),
        );
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
      () => LoginUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(
      () => LogoutUseCase(getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton(
      () => RestoreSessionUseCase(getIt<AuthRepository>()),
    );

    // ---- auth BLoC (factory — fresh bloc per BlocProvider) ------
    //
    // We *intentionally* keep the AuthBloc as a factory. The 401 →
    // logout wiring goes through [LogoutBus] (a global broadcast
    // stream) which the host that owns the bloc — see
    // `_DesktopShellGate` in `main.dart` — subscribes to. That way the
    // interceptor never has to reach into a singleton bloc, and
    // hot-restart / multiple BlocProvider instances all work
    // naturally.
    getIt.registerFactory<AuthBloc>(
      () => AuthBloc(
        login: getIt<LoginUseCase>(),
        logout: getIt<LogoutUseCase>(),
        restoreSession: getIt<RestoreSessionUseCase>(),
      ),
    );
  }
}
