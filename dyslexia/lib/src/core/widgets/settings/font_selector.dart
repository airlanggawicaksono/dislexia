import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:silky_scroll/silky_scroll.dart';

import '../../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../utils/font_utils.dart';

class _FontCard extends StatelessWidget {
  final int index;
  final String label;
  final String shortLabel;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _FontCard({
    required this.index,
    required this.label,
    required this.shortLabel,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final font = DyslexiaFont.values[index];
    final cardW = compact ? 72.0 : 112.0;
    final colPad = compact ? 6.0 : 10.0;
    final fontSize = compact ? 16.0 : 22.0;
    final labelS = compact ? 8.0 : 9.0;
    final selectedBg = const Color(0xFF3D5A99);
    final idleBg = const Color(0xFFEFEADF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardW,
        margin: EdgeInsets.only(right: compact ? 6 : 10),
        padding: EdgeInsets.symmetric(vertical: colPad),
        decoration: BoxDecoration(
          color: selected ? selectedBg : idleBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? selectedBg : Colors.transparent, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Aa', style: applyDyslexiaFont(font: font, baseStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black87))),
            const SizedBox(height: 4),
            Text(compact ? shortLabel : label, style: TextStyle(fontSize: labelS, color: selected ? Colors.white70 : Colors.black45), textAlign: TextAlign.center, maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class FontSelector extends StatelessWidget {
  final bool compact;
  const FontSelector({super.key, this.compact = false});

  static const _fonts = <DyslexiaFont>[
    DyslexiaFont.openDyslexic, DyslexiaFont.lexend, DyslexiaFont.plusJakartaSans,
    DyslexiaFont.sassoonPrimary, DyslexiaFont.tahoma, DyslexiaFont.weezerFont,
    DyslexiaFont.verdana, DyslexiaFont.trebuchetMS, DyslexiaFont.helvetica,
    DyslexiaFont.arial, DyslexiaFont.comicSansMS, DyslexiaFont.calibri,
  ];

  static const _labels = {
    DyslexiaFont.openDyslexic: 'OpenDyslexic', DyslexiaFont.plusJakartaSans: 'Plus Jakarta Sans',
    DyslexiaFont.lexend: 'Lexend', DyslexiaFont.sassoonPrimary: 'Sassoon Primary',
    DyslexiaFont.tahoma: 'Tahoma', DyslexiaFont.weezerFont: 'WeezerFont',
    DyslexiaFont.verdana: 'Verdana', DyslexiaFont.trebuchetMS: 'Trebuchet MS',
    DyslexiaFont.helvetica: 'Helvetica', DyslexiaFont.arial: 'Arial',
    DyslexiaFont.comicSansMS: 'Comic Sans MS', DyslexiaFont.calibri: 'Calibri',
  };

  static const _shortLabels = {
    DyslexiaFont.openDyslexic: 'OpenDys', DyslexiaFont.plusJakartaSans: 'Jakarta',
    DyslexiaFont.lexend: 'Lexend', DyslexiaFont.sassoonPrimary: 'Sassoon',
    DyslexiaFont.tahoma: 'Tahoma', DyslexiaFont.weezerFont: 'Weezer',
    DyslexiaFont.verdana: 'Verdana', DyslexiaFont.trebuchetMS: 'Trebuchet',
    DyslexiaFont.helvetica: 'Helvetica', DyslexiaFont.arial: 'Arial',
    DyslexiaFont.comicSansMS: 'Comic', DyslexiaFont.calibri: 'Calibri',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final bloc = context.read<DisplaySettingsBloc>();
        final h = compact ? 88.0 : 98.0;
        return SizedBox(
          height: h,
          child: SilkyScroll(
            direction: Axis.horizontal,
            mouseWheelVerticalDeltaBehavior: MouseWheelVerticalDeltaBehavior.always,
            builder: (context, controller, physics, deviceKind) => ListView(
              controller: controller,
              physics: physics,
              scrollDirection: Axis.horizontal,
              children: List.generate(_fonts.length, (i) {
                final f = _fonts[i];
                return _FontCard(
                  index: i,
                  label: _labels[f] ?? '',
                  shortLabel: _shortLabels[f] ?? '',
                  selected: state.settings.font == f,
                  compact: compact,
                  onTap: () => bloc.add(UpdateFontEvent(f)),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
