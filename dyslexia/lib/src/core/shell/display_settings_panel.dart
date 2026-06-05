import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/font_utils.dart';
import '../../core/widgets/adaptive/adaptive.dart';
import '../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../features/display_settings/presentation/theme/display_colors.dart';

class DisplaySettingsPanel extends StatelessWidget {
  final VoidCallback? onClose;
  const DisplaySettingsPanel({super.key, this.onClose});

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
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final bg = bgColor(state.settings.colorTheme);
        final fg = fgColor(state.settings.colorTheme);
        final s = state.settings;
        final bloc = context.read<DisplaySettingsBloc>();
        final borderColor = fg.withValues(alpha: 0.08);

        return Container(
          width: 248,
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
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: fg)),
                    if (onClose != null)
                      GestureDetector(
                        onTap: onClose,
                        child: Icon(Icons.close,
                            size: 18, color: fg.withValues(alpha: 0.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _Label(title: 'FONT', color: fg.withValues(alpha: 0.5)),
                SizedBox(
                  height: 88,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _fontOptions
                        .map((f) => _FontChip(
                            font: f,
                            selected: s.font == f,
                            onTap: () => bloc.add(UpdateFontEvent(f)),
                            surfaceColor: fg.withValues(alpha: 0.08)))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _Label(title: 'COLOR', color: fg.withValues(alpha: 0.5)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppColorTheme.values
                      .map((t) => _ColorSwatch(
                          theme: t,
                          selected: s.colorTheme == t,
                          onTap: () => bloc.add(UpdateColorThemeEvent(t))))
                      .toList(),
                ),
                const SizedBox(height: 12),
                _Label(title: 'TYPOGRAPHY', color: fg.withValues(alpha: 0.5)),
                _MiniSlider(
                    label: 'Size',
                    value: s.fontSize,
                    min: 12,
                    max: 32,
                    onChanged: (v) => bloc.add(UpdateFontSizeEvent(v))),
                _MiniSlider(
                    label: 'Line',
                    value: s.lineSpacing,
                    min: 1.0,
                    max: 3.0,
                    onChanged: (v) => bloc.add(UpdateLineSpacingEvent(v))),
                _MiniSlider(
                    label: 'Letter',
                    value: s.letterSpacing,
                    min: 0.0,
                    max: 2.0,
                    onChanged: (v) => bloc.add(UpdateLetterSpacingEvent(v))),
                _MiniSlider(
                    label: 'Word',
                    value: s.wordSpacing,
                    min: 0.0,
                    max: 8.0,
                    onChanged: (v) => bloc.add(UpdateWordSpacingEvent(v))),
                const SizedBox(height: 12),
                _Label(title: 'PRESETS', color: fg.withValues(alpha: 0.5)),
                ...DisplayPreset.values.map((p) => _PresetChip(
                    label: _presetName(p),
                    selected: s.preset == p,
                    onTap: () => bloc.add(ApplyPresetEvent(p)),
                    surfaceColor: fg.withValues(alpha: 0.08))),
                const SizedBox(height: 12),
                _Label(
                    title: 'ACCESSIBILITY', color: fg.withValues(alpha: 0.5)),
                _ToggleRow(
                  label: 'Reading Ruler',
                  value: s.rulerEnabled,
                  onToggle: () => bloc.add(ToggleRulerEvent()),
                  fgColor: fg,
                ),
                const SizedBox(height: 4),
                _ToggleRow(
                  label: 'Syllable Dots',
                  value: s.syllablesEnabled,
                  onToggle: () => bloc.add(ToggleSyllablesEvent()),
                  fgColor: fg,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _presetName(DisplayPreset p) => switch (p) {
        DisplayPreset.defaultPreset => 'Default',
        DisplayPreset.dyslexiaFriendly => 'Dyslexia Friendly',
        DisplayPreset.highContrast => 'High Contrast',
        DisplayPreset.nightMode => 'Night Mode',
        DisplayPreset.lightBlueTheme => 'Light Blue',
        DisplayPreset.greyTheme => 'Grey',
        DisplayPreset.lavenderTheme => 'Lavender',
        DisplayPreset.whiteTheme => 'White',
        DisplayPreset.skyBlueTheme => 'Sky Blue',
        DisplayPreset.mintGreenTheme => 'Mint Green',
        DisplayPreset.peachTheme => 'Peach',
      };
}

class _Label extends StatelessWidget {
  final String title;
  final Color color;
  const _Label({required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.8)),
      );
}

class _FontChip extends StatelessWidget {
  final DyslexiaFont font;
  final bool selected;
  final VoidCallback onTap;
  final Color surfaceColor;
  const _FontChip(
      {required this.font,
      required this.selected,
      required this.onTap,
      required this.surfaceColor});

  static const _labels = {
    DyslexiaFont.openDyslexic: 'OpenDys',
    DyslexiaFont.plusJakartaSans: 'Jakarta',
    DyslexiaFont.lexend: 'Lexend',
    DyslexiaFont.sassoonPrimary: 'Sassoon',
    DyslexiaFont.tahoma: 'Tahoma',
    DyslexiaFont.weezerFont: 'Weezer',
    DyslexiaFont.verdana: 'Verdana',
    DyslexiaFont.trebuchetMS: 'Trebuchet',
    DyslexiaFont.helvetica: 'Helvetica',
    DyslexiaFont.arial: 'Arial',
    DyslexiaFont.comicSansMS: 'Comic',
    DyslexiaFont.calibri: 'Calibri',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 72,
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3D5A99) : surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Aa',
                  style: applyDyslexiaFont(
                      font: font,
                      baseStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : surfaceColor.withValues(alpha: 1)))),
              const SizedBox(height: 2),
              Text(_labels[font] ?? '',
                  style: TextStyle(
                      fontSize: 8,
                      color: selected
                          ? Colors.white70
                          : surfaceColor.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                  maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final AppColorTheme theme;
  final bool selected;
  final VoidCallback onTap;
  const _ColorSwatch(
      {required this.theme, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: bgColor(theme),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: selected ? const Color(0xFF3D5A99) : Colors.black12,
                width: selected ? 2 : 1),
          ),
          child: selected
              ? const Center(
                  child: Icon(Icons.check, size: 10, color: Color(0xFF3D5A99)))
              : null,
        ),
      ),
    );
  }
}

class _MiniSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _MiniSlider(
      {required this.label,
      required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
              width: 36,
              child: Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.black45))),
          Expanded(
            child: AdaptiveSlider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: const Color(0xFF3D5A99),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color surfaceColor;
  const _PresetChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.surfaceColor});

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
            color: selected
                ? const Color(0xFF3D5A99).withValues(alpha: 0.15)
                : surfaceColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: selected ? const Color(0xFF3D5A99) : Colors.transparent,
                width: 1),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? const Color(0xFF3D5A99)
                      : surfaceColor.withValues(alpha: 1))),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onToggle;
  final Color fgColor;
  const _ToggleRow(
      {required this.label,
      required this.value,
      required this.onToggle,
      required this.fgColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: fgColor.withValues(alpha: 0.7))),
              const Spacer(),
              Container(
                width: 32,
                height: 18,
                decoration: BoxDecoration(
                  color: value
                      ? const Color(0xFF3D5A99)
                      : fgColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
