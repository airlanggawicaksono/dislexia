import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/font_utils.dart';
import '../../domain/entities/display_settings_entity.dart';
import '../bloc/display_settings/display_settings_bloc.dart';
import '../theme/display_colors.dart';

class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  static const _fontOptions = <DyslexiaFont>[
    DyslexiaFont.openDyslexic,
    DyslexiaFont.lexend,
    DyslexiaFont.plusJakartaSans,
    DyslexiaFont.sassoonPrimary,
    DyslexiaFont.tahoma,
    DyslexiaFont.weezerFont,
    DyslexiaFont.verdana,
    DyslexiaFont.trebuchetMS,
    DyslexiaFont.helvetica,
    DyslexiaFont.arial,
    DyslexiaFont.comicSansMS,
    DyslexiaFont.calibri,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Display Settings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
              _SectionLabel(title: 'FONT'),
              SizedBox(
                height: 98,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _fontOptions
                      .map((f) => _FontCard(
                            font: f,
                            selected: s.font == f,
                            onTap: () => bloc.add(UpdateFontEvent(f)),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'LIVE PREVIEW'),
              Container(
                height: 128,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor(s.colorTheme),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Center(
                  child: Text(
                    'The quick brown fox jumps over the lazy dog. '
                    'Reading should feel comfortable and natural for everyone.',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: applyDyslexiaFont(
                      font: s.font,
                      baseStyle: TextStyle(
                        fontSize: s.fontSize,
                        height: s.lineSpacing,
                        letterSpacing: s.letterSpacing,
                        wordSpacing: s.wordSpacing,
                        color: fgColor(s.colorTheme),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'BACKGROUND COLOR'),
              _ColorGrid(
                selected: s.colorTheme,
                onSelect: (t) => bloc.add(UpdateColorThemeEvent(t)),
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'TYPOGRAPHY'),
              _LabeledSlider(
                label: 'Font Size',
                value: s.fontSize,
                displayValue: '${s.fontSize.toStringAsFixed(0)}pt',
                min: 12,
                max: 32,
                onChanged: (v) => bloc.add(UpdateFontSizeEvent(v)),
                leadingLabel: 'AA',
              ),
              _LabeledSlider(
                label: 'Line Spacing',
                value: s.lineSpacing,
                displayValue: '${s.lineSpacing.toStringAsFixed(1)}x',
                min: 1.0,
                max: 3.0,
                onChanged: (v) => bloc.add(UpdateLineSpacingEvent(v)),
                leadingIcon: Icons.format_line_spacing_rounded,
              ),
              _LabeledSlider(
                label: 'Letter Spacing',
                value: s.letterSpacing,
                displayValue: '${s.letterSpacing.toStringAsFixed(1)}pt',
                min: 0.0,
                max: 2.0,
                onChanged: (v) => bloc.add(UpdateLetterSpacingEvent(v)),
                leadingLabel: 'A',
              ),
              _LabeledSlider(
                label: 'Word Spacing',
                value: s.wordSpacing,
                displayValue: '${s.wordSpacing.toStringAsFixed(1)}pt',
                min: 0.0,
                max: 8.0,
                onChanged: (v) => bloc.add(UpdateWordSpacingEvent(v)),
                leadingLabel: 'W',
              ),
              const SizedBox(height: 24),
              _SectionLabel(title: 'QUICK PRESETS'),
              ...DisplayPreset.values.map((p) => _PresetTile(
                    label: _presetLabel(p),
                    subtitle: _presetSubtitle(p),
                    selected: s.preset == p,
                    onTap: () => bloc.add(ApplyPresetEvent(p)),
                  )),
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
        DisplayPreset.defaultPreset => 'OpenDyslexic - Cream - 18pt',
        DisplayPreset.dyslexiaFriendly => 'OpenDyslexic - Cream - 20pt - 2.0x',
        DisplayPreset.highContrast => 'Plus Jakarta Sans - Dark - 22pt',
        DisplayPreset.nightMode => 'Plus Jakarta Sans - Dark - 18pt',
      };
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FontCard extends StatelessWidget {
  final DyslexiaFont font;
  final bool selected;
  final VoidCallback onTap;

  const _FontCard({
    required this.font,
    required this.selected,
    required this.onTap,
  });

  static const _labels = {
    DyslexiaFont.openDyslexic: 'OpenDyslexic',
    DyslexiaFont.plusJakartaSans: 'Plus Jakarta Sans',
    DyslexiaFont.lexend: 'Lexend',
    DyslexiaFont.sassoonPrimary: 'Sassoon Primary',
    DyslexiaFont.tahoma: 'Tahoma',
    DyslexiaFont.weezerFont: 'WeezerFont',
    DyslexiaFont.verdana: 'Verdana',
    DyslexiaFont.trebuchetMS: 'Trebuchet MS',
    DyslexiaFont.helvetica: 'Helvetica',
    DyslexiaFont.arial: 'Arial',
    DyslexiaFont.comicSansMS: 'Comic Sans MS',
    DyslexiaFont.calibri: 'Calibri',
  };

  @override
  Widget build(BuildContext context) {
    const selected_ = Color(0xFF3D5A99);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selected_ : const Color(0xFFEFEADF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selected_ : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aa',
              style: applyDyslexiaFont(
                font: font,
                baseStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _labels[font] ?? '',
              style: TextStyle(
                fontSize: 9,
                color: selected ? Colors.white70 : Colors.black45,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        final theme = entries[i];
        final color = bgColor(theme);
        final label = colorLabel(theme);
        final isSelected = selected == theme;
        return GestureDetector(
          onTap: () => onSelect(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF3D5A99) : Colors.black12,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D5A99)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF3D5A99),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 5),
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

class _LabeledSlider extends StatelessWidget {
  final String label;
  final String? leadingLabel;
  final IconData? leadingIcon;
  final String displayValue;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    required this.label,
    this.leadingLabel,
    this.leadingIcon,
    required this.displayValue,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D5A99),
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 28,
                child: leadingIcon != null
                    ? Icon(leadingIcon, size: 18, color: Colors.black45)
                    : Text(
                        leadingLabel ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black45,
                        ),
                      ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF3D5A99),
                    thumbColor: const Color(0xFF3D5A99),
                    inactiveTrackColor: Colors.black12,
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: value.clamp(min, max),
                    min: min,
                    max: max,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
