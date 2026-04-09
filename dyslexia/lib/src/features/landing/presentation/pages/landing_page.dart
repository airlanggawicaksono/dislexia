import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route_path.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _bgColor = Color(0xFFF5F0E8);
  static const _tileColor = Color(0xFFEFEADF);
  static const _iconBgColor = Color(0xFFE2DDD4);
  static const _iconColor = Color(0xFF3D5A99);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon:
                      const Icon(Icons.settings_rounded, color: Colors.black54),
                  onPressed: () =>
                      context.pushNamed(AppRoute.displaySettings.name),
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: _iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  size: 38,
                  color: _iconColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Add your text to get started',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Paste text, upload a file, or scan a\ndocument with your camera',
                style:
                    TextStyle(fontSize: 14, color: Colors.black45, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _ActionTile(
                icon: Icons.content_paste_rounded,
                label: 'Paste from Clipboard',
                onTap: () => context.pushNamed(AppRoute.scanPaste.name),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.upload_file_rounded,
                label: 'Upload File',
                onTap: () => context.pushNamed(AppRoute.upload.name),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.camera_alt_rounded,
                label: 'Scan with Camera',
                onTap: () => context.pushNamed(AppRoute.scanPaste.name),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LandingPage._tileColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.black54),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
