import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../configs/injector/injector_conf.dart';
import '../features/display_settings/presentation/pages/display_settings_page.dart';
import '../features/landing/presentation/pages/landing_page.dart';
import '../features/lens/presentation/pages/lens_page.dart';
import '../features/scan_paste/presentation/bloc/scan/scan_bloc.dart';
import '../features/scan_paste/presentation/pages/scan_paste_page.dart';
import '../features/text_pad/presentation/pages/text_pad_page.dart';
import '../features/upload/presentation/pages/upload_page.dart';
import 'app_route_path.dart';

class AppRouteConf {
  GoRouter get router => _router;

  late final _router = GoRouter(
    initialLocation: AppRoute.landing.path,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoute.landing.path,
        name: AppRoute.landing.name,
        builder: (_, __) => const LandingPage(),
      ),
      GoRoute(
        path: AppRoute.displaySettings.path,
        name: AppRoute.displaySettings.name,
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const DisplaySettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: AppRoute.upload.path,
        name: AppRoute.upload.name,
        builder: (_, __) => const UploadPage(),
      ),
      GoRoute(
        path: AppRoute.scanPaste.path,
        name: AppRoute.scanPaste.name,
        builder: (_, __) => BlocProvider(
          create: (_) => getIt<ScanBloc>(),
          child: const ScanPastePage(),
        ),
      ),
      GoRoute(
        path: AppRoute.lens.path,
        name: AppRoute.lens.name,
        builder: (_, __) => const LensPage(),
      ),
      GoRoute(
        path: AppRoute.textPad.path,
        name: AppRoute.textPad.name,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TextPadPage(
            text: extra?['text'] as String? ?? '',
            sourceName: extra?['sourceName'] as String?,
          );
        },
      ),
    ],
  );
}
