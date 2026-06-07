import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/display_settings/presentation/theme/display_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final bg = bgColor(state.settings.colorTheme);
        final fg = fgColor(state.settings.colorTheme);
        final s = state.settings;
        final bloc = context.read<DisplaySettingsBloc>();
        final borderColor = fg.withValues(alpha: 0.08);

        return LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth < 720;
            return Container(
              width: fullWidth ? double.infinity : 248,
              decoration: BoxDecoration(
                color: bg,
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Settings',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                      ],
                    ),
                    if (fullWidth) ...[
                      const SizedBox(height: 12),
                      _SectionLabel(title: 'LIVE PREVIEW', color: fg.withValues(alpha: 0.5)),
                      const LivePreview(),
                      const SizedBox(height: 12),
                    ],
                    _SectionLabel(title: 'FONT', color: fg.withValues(alpha: 0.5)),
                    FontSelector(compact: !fullWidth),
                    const SizedBox(height: 12),
                    _SectionLabel(title: 'COLOR', color: fg.withValues(alpha: 0.5)),
                    ColorSelector(compact: !fullWidth),
                    const SizedBox(height: 12),
                    _SectionLabel(title: 'TYPOGRAPHY', color: fg.withValues(alpha: 0.5)),
                    TypographySliders(compact: !fullWidth),
                    const SizedBox(height: 8),
                    _SectionLabel(title: 'ACCESSIBILITY', color: fg.withValues(alpha: 0.5)),
                    const AccessibilityToggles(),
                    const SizedBox(height: 12),
                    _SectionLabel(title: 'PRESETS', color: fg.withValues(alpha: 0.5)),
                    ...DisplayPreset.values.map((p) => _PresetChip(
                        label: _presetLabels[p] ?? '',
                        selected: s.preset == p,
                        onTap: () => bloc.add(ApplyPresetEvent(p)),
                        surfaceColor: fg.withValues(alpha: 0.08))),
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
  final bool selected;
  final VoidCallback onTap;
  final Color surfaceColor;
  const _PresetChip({required this.label, required this.selected, required this.onTap, required this.surfaceColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3D5A99).withValues(alpha: 0.15) : surfaceColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: selected ? const Color(0xFF3D5A99) : Colors.transparent, width: 1),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? const Color(0xFF3D5A99) : surfaceColor.withValues(alpha: 1))),
        ),
      ),
    );
  }
}
