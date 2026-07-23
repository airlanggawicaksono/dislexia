import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../configs/injector/injector_conf.dart';
import '../features/auth/presentation/bloc/auth/auth_bloc.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/display_settings/presentation/pages/display_settings_page.dart';
import '../features/landing/presentation/pages/landing_page.dart';
import '../features/landing/presentation/pages/desktop_landing_page.dart';
import '../core/shell/desktop_shell.dart'; 

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
  GoRouter buildRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: AppRoute.auth.path,
      debugLogDiagnostics: true,
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      
      // ✅ PERBAIKAN LOGIKA REDIRECT: Agar tidak kembali ke landing page saat refresh
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthed = authState is Authenticated;
        final isAuthLoading = authState is AuthInitial || authState is AuthLoading;
        final currentPath = state.matchedLocation;
        final isAuthRoute = currentPath == AppRoute.auth.path;

        // 1. Jika sedang memuat session (loading), JANGAN redirect ke auth.
        // Biarkan null agar tetap di halaman saat ini (misal: /desktop-shell).
        if (isAuthLoading) {
          return null; 
        }

        // 2. Jika TIDAK authenticated, paksa ke halaman auth (kecuali sudah di auth)
        if (!isAuthed) {
          return isAuthRoute ? null : AppRoute.auth.path;
        }

        // 3. Jika sudah authenticated, tapi user mencoba membuka halaman auth, 
        // arahkan ke landing page yang sesuai.
        if (isAuthRoute) {
          final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 0;
          final isDesktop = screenWidth >= 800;
          return isDesktop ? AppRoute.desktopLanding.path : AppRoute.landing.path;
        }

        // 4. Jika sudah authenticated dan berada di halaman valid (misal: /desktop-shell, /summarize), 
        // biarkan saja (return null) agar TETAP di halaman tersebut saat refresh!
        return null;
      },

      routes: [
        GoRoute(
          path: AppRoute.auth.path,
          name: AppRoute.auth.name,
          builder: (_, __) => const AuthPage(),
        ),
        GoRoute(
          path: AppRoute.desktopLanding.path,
          name: AppRoute.desktopLanding.name,
          builder: (_, __) => const DesktopLandingPage(),
        ),
        GoRoute(
          path: AppRoute.landing.path,
          name: AppRoute.landing.name,
          builder: (_, __) => const LandingPage(),
        ),
        GoRoute(
          path: AppRoute.readerLanding.path,
          name: AppRoute.readerLanding.name,
          builder: (_, __) => const LandingPage(), 
        ),

        // ✅ RUTE KHUSUS DESKTOP SHELL
        GoRoute(
          path: '/desktop-shell',
          name: 'desktop_shell',
          builder: (_, __) => const DesktopShell(),
        ),

        // ✅ RUTE MOBILE/ASLI TETAP UTUH
        GoRoute(
          path: AppRoute.displaySettings.path,
          name: AppRoute.displaySettings.name,
          pageBuilder: (_, __) => CustomTransitionPage(
            child: const DisplaySettingsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(position: animation.drive(tween), child: child);
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

String? _extraText(GoRouterState state) {
  final extra = state.extra;
  if (extra is String) return extra;
  if (extra is Map<String, dynamic>) return extra['text'] as String?;
  return null;
}

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