import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/settings/accessibility_toggles.dart';
import '../../../../core/widgets/settings/color_selector.dart';
import '../../../../core/widgets/settings/font_selector.dart';
import '../../../../core/widgets/settings/live_preview.dart';
import '../../../../core/widgets/settings/typography_sliders.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../domain/entities/display_settings_entity.dart';
import '../bloc/display_settings/display_settings_bloc.dart';

class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  static const _presetLabels = {
    DisplayPreset.defaultPreset: 'Default',
    DisplayPreset.dyslexiaFriendly: 'Dyslexia Friendly',
    DisplayPreset.highContrast: 'High Contrast',
    DisplayPreset.nightMode: 'Night Mode',
    DisplayPreset.lightBlueTheme: 'Light Blue',
    DisplayPreset.greyTheme: 'Grey',
    DisplayPreset.lavenderTheme: 'Lavender',
    DisplayPreset.whiteTheme: 'White',
    DisplayPreset.skyBlueTheme: 'Sky Blue',
    DisplayPreset.mintGreenTheme: 'Mint Green',
    DisplayPreset.peachTheme: 'Peach',
  };

  static const _presetSubtitles = {
    DisplayPreset.defaultPreset: 'OpenDyslexic - Cream - 18pt',
    DisplayPreset.dyslexiaFriendly: 'OpenDyslexic - Cream - 20pt - 2.0x',
    DisplayPreset.highContrast: 'Plus Jakarta Sans - Dark - 22pt',
    DisplayPreset.nightMode: 'Plus Jakarta Sans - Dark - 18pt',
    DisplayPreset.lightBlueTheme: 'Sassoon Primary - Light Blue - 18pt',
    DisplayPreset.greyTheme: 'Tahoma - Grey - 18pt',
    DisplayPreset.lavenderTheme: 'Sassoon Primary - Lavender - 18pt',
    DisplayPreset.whiteTheme: 'OpenDyslexic - White - 18pt',
    DisplayPreset.skyBlueTheme: 'Plus Jakarta Sans - Sky Blue - 18pt',
    DisplayPreset.mintGreenTheme: 'Lexend - Mint Green - 18pt',
    DisplayPreset.peachTheme: 'Sassoon Primary - Peach - 18pt',
  };

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      title: 'Display Settings',
      titleColor: Colors.black87,
      body: BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
        builder: (context, state) {
          final s = state.settings;
          final bloc = context.read<DisplaySettingsBloc>();
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              _SectionLabel(title: 'LIVE PREVIEW'),
              const LivePreview(),
              const SizedBox(height: 24),
              _SectionLabel(title: 'FONT'),
              const FontSelector(),
              const SizedBox(height: 24),
              _SectionLabel(title: 'BACKGROUND COLOR'),
              const ColorSelector(),
              const SizedBox(height: 24),
              _SectionLabel(title: 'TYPOGRAPHY'),
              const TypographySliders(),
              const SizedBox(height: 24),
              _SectionLabel(title: 'ACCESSIBILITY'),
              const AccessibilityToggles(),
              const SizedBox(height: 24),
              _SectionLabel(title: 'QUICK PRESETS'),
              ...DisplayPreset.values.map((p) => _PresetTile(
                    label: _presetLabels[p] ?? '',
                    subtitle: _presetSubtitles[p] ?? '',
                    selected: s.preset == p,
                    onTap: () => bloc.add(ApplyPresetEvent(p)),
                  )),
              const SizedBox(height: 24),
              _SectionLabel(title: 'ACCOUNT'),
              const _LogoutButton(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  Future<void> _confirmAndLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      // Router redirect bounces to /auth once the bloc goes Unauthenticated.
      context.read<AuthBloc>().add(const LogoutEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmAndLogout(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFC62828).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, size: 20, color: Color(0xFFC62828)),
            SizedBox(width: 12),
            Text('Log out',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFC62828))),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45, letterSpacing: 0.8)),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _PresetTile({required this.label, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3D5A99).withValues(alpha: 0.1) : const Color(0xFFEFEADF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF3D5A99) : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF3D5A99), size: 20),
          ],
        ),
      ),
    );
  }
}
