import 'package:flutter/material.dart';

/// Branded loading screen: owl logo + wordmark + spinner on the themed
/// background. Shown whenever the app is initializing or restoring — it
/// continues seamlessly from the native launch splash so the user never
/// sees a bare spinner or a flash of the wrong screen.
///
/// Reuse this anywhere a "starting up / please wait" state is needed
/// (auth restore, first load, etc.) instead of a plain
/// [CircularProgressIndicator].
class AppSplash extends StatelessWidget {
  /// Optional line under the wordmark (e.g. "Restoring session…").
  final String? message;

  const AppSplash({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_owl.png',
              height: 96,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              'Dyslexia',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: 28),
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
