import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app.dart';
import 'src/configs/adapter/adapter_conf.dart';
import 'src/configs/injector/injector_conf.dart';
import 'src/core/constants/list_translation_locale.dart';
import 'src/core/shell/desktop_shell.dart';
import 'src/core/utils/observer.dart';

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
    // Web platform renders desktop shell for better UX
    if (kIsWeb) {
      return const DesktopShell();
    }
    // Mobile/native platforms use existing GoRouter-based app
    return const MyApp();
  }
}
