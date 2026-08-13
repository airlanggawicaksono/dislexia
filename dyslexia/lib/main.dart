import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsBinding;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'src/configs/adapter/adapter_conf.dart';
import 'src/configs/injector/injector_conf.dart';
import 'src/core/api/api_url.dart';
import 'src/core/constants/list_translation_locale.dart';
import 'src/routes/app_route_conf.dart'; 
import 'src/core/utils/observer.dart';
import 'src/core/themes/app_theme.dart';

// Import BLoC
import 'src/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'src/features/auth/presentation/bloc/logout_bus.dart';
import 'src/core/blocs/theme/theme_bloc.dart';
import 'src/features/sidebar/presentation/bloc/sidebar/sidebar_bloc.dart';
import 'src/features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import 'src/features/reader/presentation/bloc/reader_shell/reader_shell_bloc.dart';
import 'src/features/summarize/presentation/bloc/summarize_bloc.dart';
import 'src/features/define/presentation/bloc/define_bloc.dart';
import 'src/features/professionalize/presentation/bloc/professionalize_bloc.dart';
import 'src/features/screening/presentation/bloc/screening_bloc.dart';

// ✅ IMPORT FONT HELPER
import 'src/core/utils/font_utils.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The web app renders via Flutter's canvas (CanvasKit). Force the
  // semantics tree to be built up-front so screen readers and assistive
  // tech can interact with the app instead of hitting an inert canvas.
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }

  await EasyLocalization.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = true;
  ApiUrl.configure(baseUrlOverride: const String.fromEnvironment('API_BASE_URL'));
  configureAdapter();
  configureDepedencies();
  Bloc.observer = AppBlocObserver();

  runApp(
    EasyLocalization(
      supportedLocales: const [indonesiaLocale, englishLocale],
      path: "assets/translations",
      startLocale: indonesiaLocale,
      child: const DyslexiaApp(),
    ),
  );
}

class DyslexiaApp extends StatelessWidget {
  const DyslexiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()..add(const RestoreSessionEvent())),
        BlocProvider<ThemeBloc>(create: (_) => getIt<ThemeBloc>()),
        BlocProvider<SidebarBloc>(create: (_) => SidebarBloc()),
        BlocProvider<DisplaySettingsBloc>(create: (_) => getIt<DisplaySettingsBloc>()),
        BlocProvider<ReaderShellBloc>(create: (_) => getIt<ReaderShellBloc>()),
        BlocProvider<SummarizeBloc>(create: (_) => getIt<SummarizeBloc>()),
        BlocProvider<DefineBloc>(create: (_) => getIt<DefineBloc>()),
        BlocProvider<ProfessionalizeBloc>(create: (_) => getIt<ProfessionalizeBloc>()),
        BlocProvider<ScreeningBloc>(create: (_) => getIt<ScreeningBloc>()),
      ],
      child: const _AppRouterWrapper(),
    );
  }
}

class _AppRouterWrapper extends StatefulWidget {
  const _AppRouterWrapper();
  @override
  State<_AppRouterWrapper> createState() => _AppRouterWrapperState();
}

class _AppRouterWrapperState extends State<_AppRouterWrapper> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouteConf().buildRouter(context.read<AuthBloc>());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, displayState) {
        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final baseTheme = AppTheme.data(themeState.isDarkMode);
            
            // Use applyDyslexiaFontToTextTheme so google_fonts' async font
            // loading + rebuild-on-load works on web.
            final ThemeData updatedTheme = baseTheme.copyWith(
              textTheme: applyDyslexiaFontToTextTheme(
                font: displayState.settings.font,
                textTheme: baseTheme.textTheme,
              ),
              primaryTextTheme: applyDyslexiaFontToTextTheme(
                font: displayState.settings.font,
                textTheme: baseTheme.primaryTextTheme,
              ),
            );

            return LogoutListener(
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                theme: updatedTheme,
                
                // ✅ PERBAIKAN: Buat ThemeData eksplisit dengan fontFamily
                builder: (context, child) {
                  return Theme(
                    data: updatedTheme,
                    child: DefaultTextStyle(
                      style: applyDyslexiaFont(
                        font: displayState.settings.font,
                        baseStyle: const TextStyle(),
                      ),
                      child: child!,
                    ),
                  );
                },
                
                routerConfig: _router, 
              ),
            );
          },
        );
      },
    );
  }
}

class LogoutListener extends StatefulWidget {
  final Widget child;
  const LogoutListener({super.key, required this.child});
  @override
  State<LogoutListener> createState() => _LogoutListenerState();
}

class _LogoutListenerState extends State<LogoutListener> {
  StreamSubscription<void>? _logoutSub;
  @override
  void initState() {
    super.initState();
    _logoutSub = LogoutBus.stream.listen((_) {
      if (!mounted) return;
      final bloc = context.read<AuthBloc>();
      if (bloc.state is Authenticated) bloc.add(const LogoutEvent());
    });
  }
  @override
  void dispose() { _logoutSub?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => widget.child;
}