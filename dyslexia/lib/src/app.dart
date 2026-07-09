import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'configs/injector/injector_conf.dart';
import 'core/blocs/theme/theme_bloc.dart';
import 'core/themes/app_theme.dart';
import 'features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'features/auth/presentation/bloc/logout_bus.dart';
import 'features/display_settings/domain/entities/display_settings_entity.dart';
import 'features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import 'features/display_settings/presentation/theme/display_colors.dart';
import 'routes/app_route_conf.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // One AuthBloc for the whole mobile app lifetime. It drives both the
  // GoRouter auth gate (via the router's refreshListenable/redirect) and
  // the AuthPage, so both see the same instance. Restore any stored
  // session on boot before the first frame so a returning user lands
  // straight in the app instead of flashing the login screen.
  late final AuthBloc _authBloc;
  late final _router = getIt<AppRouteConf>().buildRouter(_authBloc);
  StreamSubscription<void>? _logoutSub;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const RestoreSessionEvent());
    // A 401 on any authenticated request fires LogoutBus (from the
    // AuthInterceptor). Translate it into a LogoutEvent so the session is
    // cleared and the router's redirect bounces the user to /auth.
    _logoutSub = LogoutBus.stream.listen((_) {
      if (!mounted) return;
      if (_authBloc.state is Authenticated) {
        _authBloc.add(const LogoutEvent());
      }
    });
  }

  @override
  void dispose() {
    _logoutSub?.cancel();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      useInheritedMediaQuery: true,
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => GestureDetector(
        onTap: () => primaryFocus?.unfocus(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: _authBloc),
            BlocProvider(
              create: (_) => getIt<ThemeBloc>(),
            ),
            BlocProvider(
              create: (_) => getIt<DisplaySettingsBloc>(),
            ),
          ],
          // The global theme depends on auth state:
          //  * logged out / freshly logged in → off-white auth palette
          //  * logged in → follow the user's display-settings colour
          //    (stored device-locally via SharedPreferences).
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
                builder: (context, dsState) {
                  final ThemeData theme;
                  if (authState is Authenticated) {
                    final ct = dsState.settings.colorTheme;
                    theme = AppTheme.fromColors(
                      background: bgColor(ct),
                      foreground: fgColor(ct),
                      isDark: ct == AppColorTheme.dark,
                    );
                  } else {
                    theme = AppTheme.fromColors(
                      background: AppTheme.authSurface,
                      foreground: AppTheme.authForeground,
                      isDark: false,
                    );
                  }
                  return MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: context.locale,
                    theme: theme,
                    routerConfig: _router,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
