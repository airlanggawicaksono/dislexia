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
import 'src/core/constants/list_translation_locale.dart';
import 'src/core/shell/desktop_shell.dart';
import 'src/core/utils/observer.dart';
import 'src/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'src/features/auth/presentation/pages/auth_page.dart';

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
        create: (_) =>
            getIt<AuthBloc>()..add(const RestoreSessionEvent()),
        child: const _DesktopShellGate(),
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
class _DesktopShellGate extends StatelessWidget {
  const _DesktopShellGate();

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
