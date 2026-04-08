import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/display_settings/presentation/pages/display_settings_page.dart';
import '../features/landing/presentation/pages/landing_page.dart';
import '../features/lens/presentation/pages/lens_page.dart';
import '../features/scan_paste/presentation/pages/scan_paste_page.dart';
import '../features/text_pad/presentation/pages/text_pad_page.dart';
import '../features/upload/presentation/pages/upload_page.dart';
import 'app_route_path.dart';
import 'routes.dart';

class AppRouteConf {
  GoRouter get router => _router;

  late final _router = GoRouter(
    initialLocation: AppRoute.auth.path,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoute.auth.path,
        name: AppRoute.auth.name,
        builder: (_, __) => const AuthPage(),
        routes: [
          GoRoute(
            path: AppRoute.login.path,
            name: AppRoute.login.name,
            builder: (_, __) => const LoginPage(),
          ),
          GoRoute(
            path: AppRoute.register.path,
            name: AppRoute.register.name,
            builder: (_, __) => const RegisterPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        builder: (_, state) {
          final params = state.pathParameters;
          final user = UserEntity(
            username: params["username"],
            email: params["email"],
            userId: params["user_id"],
          );

          return HomePage(user: user);
        },
      ),
      GoRoute(
        path: AppRoute.createProduct.path,
        name: AppRoute.createProduct.name,
        builder: (_, state) {
          final context = state.extra as BuildContext;

          return CreateProductPage(ctx: context);
        },
      ),
      GoRoute(
        path: AppRoute.updateProduct.path,
        name: AppRoute.updateProduct.name,
        builder: (_, state) {
          final context = state.extra as BuildContext;
          final params = state.pathParameters;

          final product = UpdateProductParams(
            productId: params["product_id"] ?? "",
            name: params["product_name"] ?? "",
            price: int.tryParse(params["product_price"] ?? "") ?? 0,
          );

          return UpdateProductPage(
            ctx: context,
            productParams: product,
          );
        },
      ),
      GoRoute(
        path: AppRoute.landing.path,
        name: AppRoute.landing.name,
        builder: (_, __) => const LandingPage(),
      ),
      GoRoute(
        path: AppRoute.displaySettings.path,
        name: AppRoute.displaySettings.name,
        builder: (_, __) => const DisplaySettingsPage(),
      ),
      GoRoute(
        path: AppRoute.upload.path,
        name: AppRoute.upload.name,
        builder: (_, __) => const UploadPage(),
      ),
      GoRoute(
        path: AppRoute.scanPaste.path,
        name: AppRoute.scanPaste.name,
        builder: (_, __) => const ScanPastePage(),
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
