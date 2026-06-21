import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../widgets/settings/accessibility_toggles.dart';
import '../widgets/settings/color_selector.dart';
import '../widgets/settings/font_selector.dart';
import '../widgets/settings/live_preview.dart';
import '../widgets/settings/typography_sliders.dart';

class DisplaySettingsPanel extends StatelessWidget {
  const DisplaySettingsPanel({super.key});

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
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final s = state.settings;
        final theme = Theme.of(context);
        final bloc = context.read<DisplaySettingsBloc>();

        return LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth < 720;
            return Container(
              width: fullWidth ? double.infinity : 248,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Settings',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                      ],
                    ),
                    if (fullWidth) ...[
                      const SizedBox(height: 12),
                      _SectionLabel(title: 'LIVE PREVIEW', color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      const LivePreview(),
                      const SizedBox(height: 12),
                    ],
                    _SectionLabel(title: 'FONT', color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const FontSelector(),
                    const SizedBox(height: 12),
                    _SectionLabel(title: 'BACKGROUND COLOR', color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ColorSelector(compact: !fullWidth),
                    const SizedBox(height: 12),
                    _SectionLabel(title: 'TYPOGRAPHY', color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    TypographySliders(compact: !fullWidth),
                    const SizedBox(height: 8),
                    _SectionLabel(title: 'ACCESSIBILITY', color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const AccessibilityToggles(),
                    const SizedBox(height: 12),
                    _SectionLabel(title: 'PRESETS', color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ...DisplayPreset.values.map((p) => _PresetChip(
                        label: _presetLabels[p] ?? '',
                        subtitle: _presetSubtitles[p] ?? '',
                        selected: s.preset == p,
                        onTap: () => bloc.add(ApplyPresetEvent(p)),
                        surfaceColor: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionLabel({required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.8)),
      );
}

class _PresetChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color surfaceColor;
  const _PresetChip({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3D5A99).withValues(alpha: 0.15) : surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? const Color(0xFF3D5A99) : Colors.transparent, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? const Color(0xFF3D5A99) : surfaceColor.withValues(alpha: 1))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 9,
                      color: selected ? const Color(0xFF3D5A99).withValues(alpha: 0.7) : Colors.black45),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
