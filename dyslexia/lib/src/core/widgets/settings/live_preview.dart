import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../features/display_settings/presentation/theme/display_colors.dart';
import '../../../features/reader/data/syllabifier.dart';
import '../../utils/font_utils.dart';
import '../word_highlight_text.dart';

class LivePreview extends StatelessWidget {
  const LivePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        final s = state.settings;
        final bg = bgColor(s.colorTheme);
        final fg = fgColor(s.colorTheme);
        final borderColor = fg.withValues(alpha: 0.2);
        return Container(
          height: 128,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: WordHighlightText(
              text: s.syllablesEnabled
                  ? syllabify('The quick brown fox jumps over the lazy dog. '
                      'Reading should feel comfortable and natural for everyone.')
                  : 'The quick brown fox jumps over the lazy dog. '
                      'Reading should feel comfortable and natural for everyone.',
              style: applyDyslexiaFont(
                font: s.font,
                baseStyle: TextStyle(
                  fontSize: s.fontSize,
                  height: s.lineSpacing,
                  letterSpacing: s.letterSpacing,
                  wordSpacing: s.wordSpacing,
                  color: fg,
                ),
              ),
              maxWidth: double.infinity,
            ),
          ),
        );
      },
    );
  }
}
