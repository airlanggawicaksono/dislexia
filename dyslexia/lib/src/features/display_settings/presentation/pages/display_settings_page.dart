import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/display_settings_model.dart';
import '../../domain/entities/display_settings_entity.dart';
import '../bloc/display_settings/display_settings_bloc.dart';
import '../theme/display_colors.dart';
import '../theme/display_fonts.dart';

class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Display Settings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
        builder: (context, state) {
          final s = state.settings;
          final bloc = context.read<DisplaySettingsBloc>();
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              _Section(
                title: 'LIVE PREVIEW',
                child: _PreviewCard(settings: s),
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'FONT',
                child: _FontPicker(
                  selected: s.font,
                  onSelect: (f) => bloc.add(UpdateFontEvent(f)),
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'BACKGROUND COLOR',
                child: _ColorGrid(
                  selected: s.colorTheme,
                  onSelect: (t) => bloc.add(UpdateColorThemeEvent(t)),
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'TYPOGRAPHY',
                child: Column(
                  children: [
                    _SpacingSlider(
                      leadingLabel: 'AA',
                      trailingValue: '${s.fontSize.toStringAsFixed(0)}pt',
                      value: s.fontSize,
                      min: 12,
                      max: 32,
                      onChanged: (v) => bloc.add(UpdateFontSizeEvent(v)),
                    ),
                    _SpacingSlider(
                      leadingIcon: Icons.format_line_spacing_rounded,
                      trailingValue: '${s.lineSpacing.toStringAsFixed(1)}x',
                      value: s.lineSpacing,
                      min: 1.0,
                      max: 3.0,
                      onChanged: (v) => bloc.add(UpdateLineSpacingEvent(v)),
                    ),
                    _SpacingSlider(
                      leadingLabel: 'A',
                      trailingValue: '${s.letterSpacing.toStringAsFixed(1)}pt',
                      value: s.letterSpacing,
                      min: 0.0,
                      max: 2.0,
                      onChanged: (v) => bloc.add(UpdateLetterSpacingEvent(v)),
                    ),
                    _SpacingSlider(
                      leadingLabel: 'W',
                      trailingValue: '${s.wordSpacing.toStringAsFixed(1)}pt',
                      value: s.wordSpacing,
                      min: 0.0,
                      max: 8.0,
                      onChanged: (v) => bloc.add(UpdateWordSpacingEvent(v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'QUICK PRESETS',
                child: Column(
                  children: DisplayPreset.values
                      .map((p) => _PresetTile(
                            label: _presetLabel(p),
                            subtitle: _presetSubtitle(p),
                            selected: s.preset == p,
                            onTap: () => bloc.add(ApplyPresetEvent(p)),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _presetLabel(DisplayPreset p) => switch (p) {
        DisplayPreset.defaultPreset => 'Default',
        DisplayPreset.dyslexiaFriendly => 'Dyslexia Friendly',
        DisplayPreset.highContrast => 'High Contrast',
        DisplayPreset.nightMode => 'Night Mode',
      };

  String _presetSubtitle(DisplayPreset p) => switch (p) {
        DisplayPreset.defaultPreset => 'OpenDyslexic · Cream · 18pt',
        DisplayPreset.dyslexiaFriendly => 'OpenDyslexic · Cream · 20pt · 2.0x',
        DisplayPreset.highContrast => 'Lexend · Dark · 22pt',
        DisplayPreset.nightMode => 'Lexend · Dark · 18pt',
      };
}

// ── Live preview ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final DisplaySettingsModel settings;

  const _PreviewCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final bg = bgColor(settings.colorTheme);
    final fg = fgColor(settings.colorTheme);

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'The quick brown fox jumps over the lazy dog.\nReading should feel comfortable and natural.',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: settings.fontSize,
            fontFamily: fontFamily(settings.font),
            color: fg,
            height: settings.lineSpacing,
            letterSpacing: settings.letterSpacing,
            wordSpacing: settings.wordSpacing,
          ),
        ),
      ),
    );
  }
}

// ── Font picker ─────────────────────────────────────────────────────────────

class _FontPicker extends StatelessWidget {
  final DyslexiaFont selected;
  final ValueChanged<DyslexiaFont> onSelect;

  const _FontPicker({required this.selected, required this.onSelect});

  static const _fonts = [
    (DyslexiaFont.openDyslexic, 'OpenDyslexic'),
    (DyslexiaFont.verdana, 'Verdana'),
    (DyslexiaFont.jakartaSans, 'Jakarta Sans'),
    (DyslexiaFont.arial, 'Arial'),
    (DyslexiaFont.calibri, 'Calibri'),
    (DyslexiaFont.lexend, 'Lexend'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _fonts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (font, label) = _fonts[i];
          final isSelected = selected == font;
          return GestureDetector(
            onTap: () => onSelect(font),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 47,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF3D5A99)
                          : const Color(0xFFEFEADF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3D5A99)
                            : Colors.transparent,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: fontFamily(font),
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Colour grid ────────────────────────────────────────────────────────────

class _ColorGrid extends StatelessWidget {
  final AppColorTheme selected;
  final ValueChanged<AppColorTheme> onSelect;

  const _ColorGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final entries = AppColorTheme.values.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final theme = entries[i];
        final color = bgColor(theme);
        final label = colorLabel(theme);
        final isSelected = selected == theme;
        return GestureDetector(
          onTap: () => onSelect(theme),
          child: Column(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3D5A99)
                            : Colors.black12,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check_rounded,
                                size: 20, color: Color(0xFF3D5A99)),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: Colors.black54),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Slider row ──────────────────────────────────────────────────────────────

class _SpacingSlider extends StatelessWidget {
  final String? leadingLabel;
  final IconData? leadingIcon;
  final String trailingValue;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SpacingSlider({
    this.leadingLabel,
    this.leadingIcon,
    required this.trailingValue,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: leadingIcon != null
                ? Icon(leadingIcon, size: 18, color: Colors.black54)
                : Text(
                    leadingLabel ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54),
                  ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF3D5A99),
                thumbColor: const Color(0xFF3D5A99),
                inactiveTrackColor: Colors.black12,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              trailingValue,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preset tile ─────────────────────────────────────────────────────────────

class _PresetTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3D5A99).withValues(alpha: 0.1)
              : const Color(0xFFEFEADF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF3D5A99) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black45)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF3D5A99), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
