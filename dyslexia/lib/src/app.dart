import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'configs/injector/injector_conf.dart';
import 'core/blocs/theme/theme_bloc.dart';
import 'core/themes/app_theme.dart';
import 'features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'features/auth/presentation/bloc/logout_bus.dart';

import 'features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import 'features/display_settings/presentation/theme/display_colors.dart';
import 'routes/app_route_conf.dart';

// ✅ IMPORT FONT HELPER
import 'core/utils/font_utils.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;
  StreamSubscription<void>? _logoutSub;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const RestoreSessionEvent());
    
    // ✅ Router dibuat SEKALI di initState agar tidak reset saat font berubah
    _router = getIt<AppRouteConf>().buildRouter(_authBloc);
    
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
            BlocProvider(create: (_) => getIt<ThemeBloc>()),
            BlocProvider(create: (_) => getIt<DisplaySettingsBloc>()),
          ],
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
                builder: (context, dsState) {
                  final ThemeData baseTheme;
                  if (authState is Authenticated) {
                    final ct = dsState.settings.colorTheme;
                    baseTheme = AppTheme.fromColors(
                      background: bgColor(ct),
                      foreground: fgColor(ct),
                      isDark: false,
                    );
                  } else {
                    baseTheme = AppTheme.fromColors(
                      background: AppTheme.authSurface,
                      foreground: AppTheme.authForeground,
                      isDark: false,
                    );
                  }

                  // ✅ Terapkan font global untuk Mobile
                  final String currentFontFamily = getGlobalFontFamily(dsState.settings.font);
                  
                  // ✅ PERBAIKAN: Gunakan copyWith HANYA untuk textTheme agar bebas dari error analyzer
                  final ThemeData updatedTheme = baseTheme.copyWith(
                    textTheme: baseTheme.textTheme.apply(fontFamily: currentFontFamily),
                    primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: currentFontFamily),
                  );

                  return MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: context.locale,
                    theme: updatedTheme,
                    
                    // ✅ Paksa semua teks di aplikasi mobile untuk inherit font ini
                    builder: (context, child) {
                      return Theme(
                        data: updatedTheme,
                        child: DefaultTextStyle(
                          style: TextStyle(fontFamily: currentFontFamily),
                          child: child!,
                        ),
                      );
                    },
                    
                    // Gunakan instance router yang STABIL (dibuat di initState)
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