import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../configs/injector/injector_conf.dart';
import '../features/auth/presentation/bloc/auth/auth_bloc.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/display_settings/presentation/pages/display_settings_page.dart';
import '../features/landing/presentation/pages/landing_page.dart';
import '../features/lens/presentation/bloc/lens/lens_bloc.dart';
import '../features/lens/presentation/pages/lens_page.dart';
import '../features/scan_paste/presentation/bloc/scan/scan_bloc.dart';
import '../features/scan_paste/presentation/pages/scan_paste_page.dart';
import '../features/text_pad/presentation/pages/text_pad_page.dart';
import '../features/upload/presentation/bloc/upload/upload_bloc.dart';
import '../features/upload/presentation/pages/upload_page.dart';
import '../features/summarize/presentation/bloc/summarize_bloc.dart';
import '../features/summarize/presentation/pages/summarize_page.dart';
import '../features/define/presentation/bloc/define_bloc.dart';
import '../features/define/presentation/pages/define_page.dart';
import '../features/professionalize/presentation/bloc/professionalize_bloc.dart';
import '../features/professionalize/presentation/pages/professionalize_page.dart';
import '../features/screening/presentation/bloc/screening_bloc.dart';
import '../features/screening/presentation/pages/screening_page.dart';
import 'app_route_path.dart';

class AppRouteConf {
  /// Build the app router bound to [authBloc]. The bloc drives the
  /// auth gate: unauthenticated users are bounced to [AppRoute.auth],
  /// authenticated users are kept out of it. The router re-evaluates
  /// [redirect] whenever the bloc emits (via [refreshListenable]).
  GoRouter buildRouter(AuthBloc authBloc) {
    return GoRouter(
      // Start on the auth screen. While the session is being restored the
      // AuthPage shows a spinner (see AuthInitial handling there), so a
      // returning user sees the login screen briefly, never the main app.
      // Once restore resolves, the redirect below routes accordingly.
      initialLocation: AppRoute.auth.path,
      debugLogDiagnostics: true,
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final atAuth = state.matchedLocation == AppRoute.auth.path;

        // Session restore in flight — hold on /auth (which renders a spinner)
        // instead of letting the initial location fall through to the app.
        if (authState is AuthInitial || authState is AuthLoading) {
          return atAuth ? null : AppRoute.auth.path;
        }

        final isAuthed = authState is Authenticated;
        if (!isAuthed) return atAuth ? null : AppRoute.auth.path;
        // Logged in but sitting on /auth → send to the app.
        if (atAuth) return AppRoute.landing.path;
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoute.auth.path,
          name: AppRoute.auth.name,
          builder: (_, __) => const AuthPage(),
        ),
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
          builder: (_, __) => BlocProvider(
            create: (_) => getIt<UploadBloc>(),
            child: const UploadPage(),
          ),
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
          builder: (_, __) => BlocProvider(
            create: (_) => getIt<LensBloc>(),
            child: const LensPage(),
          ),
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
        // These blocs are lazySingletons (see *_dependency.dart). Use
        // BlocProvider.value so navigating away doesn't close the singleton
        // (create: would close it on pop → "add after close" on next visit).
        // .value also lets the last result survive navigate-away-and-back.
        GoRoute(
          path: AppRoute.summarize.path,
          name: AppRoute.summarize.name,
          builder: (_, state) => BlocProvider.value(
            value: getIt<SummarizeBloc>(),
            child: SummarizePage(initialText: _extraText(state)),
          ),
        ),
        GoRoute(
          path: AppRoute.define.path,
          name: AppRoute.define.name,
          builder: (_, state) => BlocProvider.value(
            value: getIt<DefineBloc>(),
            child: DefinePage(initialText: _extraText(state)),
          ),
        ),
        GoRoute(
          path: AppRoute.professionalize.path,
          name: AppRoute.professionalize.name,
          builder: (_, state) => BlocProvider.value(
            value: getIt<ProfessionalizeBloc>(),
            child: ProfessionalizePage(initialText: _extraText(state)),
          ),
        ),
        GoRoute(
          path: AppRoute.screening.path,
          name: AppRoute.screening.name,
          builder: (_, __) => BlocProvider.value(
            value: getIt<ScreeningBloc>(),
            child: const ScreeningPage(),
          ),
        ),
      ],
    );
  }
}

/// Pull optional pre-fill text passed via `extra` — either a plain String or
/// a `{'text': ...}` map (matches the textPad convention).
String? _extraText(GoRouterState state) {
  final extra = state.extra;
  if (extra is String) return extra;
  if (extra is Map<String, dynamic>) return extra['text'] as String?;
  return null;
}

/// Bridges a [Stream] (the AuthBloc's state stream) to a [Listenable] so
/// GoRouter re-runs its [GoRouter.redirect] on every auth transition.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
