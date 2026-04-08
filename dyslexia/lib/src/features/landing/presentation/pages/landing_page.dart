import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route_path.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dyslexia App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LandingButton(
              label: 'Display Settings',
              icon: Icons.display_settings_rounded,
              onTap: () => context.pushNamed(AppRoute.displaySettings.name),
            ),
            const SizedBox(height: 16),
            _LandingButton(
              label: 'Upload',
              icon: Icons.upload_rounded,
              onTap: () => context.pushNamed(AppRoute.upload.name),
            ),
            const SizedBox(height: 16),
            _LandingButton(
              label: 'Scan & Paste',
              icon: Icons.document_scanner_rounded,
              onTap: () => context.pushNamed(AppRoute.scanPaste.name),
            ),
            const SizedBox(height: 16),
            _LandingButton(
              label: 'Lens',
              icon: Icons.camera_rounded,
              onTap: () => context.pushNamed(AppRoute.lens.name),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _LandingButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
