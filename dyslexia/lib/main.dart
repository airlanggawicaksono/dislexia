import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app.dart';
import 'src/configs/adapter/adapter_conf.dart';
import 'src/configs/injector/injector_conf.dart';
import 'src/core/api/api_url.dart';
import 'src/core/constants/list_translation_locale.dart';
import 'src/core/shell/desktop_shell.dart';
import 'src/core/utils/observer.dart';
import 'src/core/themes/app_theme.dart';
import 'src/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'src/features/auth/presentation/bloc/logout_bus.dart';
import 'src/features/auth/presentation/pages/auth_page.dart';
import 'src/core/blocs/theme/theme_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Hive.initFlutter();
  if (kIsWeb) {
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory.web,
    );
  } else {
    final path = await getTemporaryDirectory();
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(path.path),
    );
  }

  // Apply any build-time / env-time base URL override before the DI
  // container (and therefore the Dio client) is constructed, so the
  // very first request goes to the configured host. The flag is read
  // via --dart-define=API_BASE_URL=https://...
  ApiUrl.configure(
    baseUrlOverride: const String.fromEnvironment('API_BASE_URL'),
  );

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
    // Web platform renders the desktop shell. The shell is wrapped in a
    // [BlocProvider] for [AuthBloc] so the auth page (shown when the
    // user is logged out) and the rest of the shell can both dispatch
    // events on the same bloc instance.
    if (kIsWeb) {
      return BlocProvider<AuthBloc>(
        create: (_) => getIt<AuthBloc>()..add(const RestoreSessionEvent()),
        child: BlocProvider(
          create: (_) => getIt<ThemeBloc>(),
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                theme: AppTheme.data(state.isDarkMode),
                home: const _DesktopShellGate(),
              );
            },
          ),
        ),
      );
    }
    // Mobile/native platforms use the existing GoRouter-based app.
    return const MyApp();
  }
}

/// Tiny gate that swaps between the [AuthPage] and the full
/// [DesktopShell] based on the current [AuthState]. Kept separate from
/// [DyslexiaApp] so [BlocProvider] is only constructed once for the
/// entire web experience.
///
/// In addition to rendering, this widget also wires the [LogoutBus]
/// (a global broadcast stream) into the [AuthBloc]: whenever the
/// [AuthInterceptor] sees a 401 on an authenticated request, the bus
/// fires and we dispatch a [LogoutEvent] on the bloc. That keeps the
/// session-expired path on the same state machine the user would use
/// to sign out manually.
class _DesktopShellGate extends StatefulWidget {
  const _DesktopShellGate();

  @override
  State<_DesktopShellGate> createState() => _DesktopShellGateState();
}

class _DesktopShellGateState extends State<_DesktopShellGate> {
  StreamSubscription<void>? _logoutSub;

  @override
  void initState() {
    super.initState();
    // Listen to the bus at the gateway so any 401 fired by the
    // AuthInterceptor gets translated into a LogoutEvent on the
    // hosted AuthBloc.
    _logoutSub = LogoutBus.stream.listen((_) {
      if (!mounted) return;
      final bloc = context.read<AuthBloc>();
      // No-op if the user is already signed out — saves us from a
      // redundant storage wipe and a needless re-emit.
      if (bloc.state is Authenticated) {
        bloc.add(const LogoutEvent());
      }
    });
  }

  @override
  void dispose() {
    _logoutSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      // We only care about the authenticated / unauthenticated buckets
      // here — initial + loading both render the shell so users see the
      // loading indicator instead of a flash of the auth page on the
      // first launch when the session is being restored.
      buildWhen: (prev, curr) =>
          curr is Authenticated || curr is Unauthenticated,
      builder: (context, state) {
        if (state is Authenticated) {
          return const DesktopShell();
        }
        return const AuthPage();
      },
    );
  }
}
