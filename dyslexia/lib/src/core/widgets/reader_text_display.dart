import 'package:flutter/material.dart';

import '../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../features/reader/data/syllabifier.dart';
import '../utils/font_utils.dart';
import 'ruler/reading_ruler.dart';
import 'word_highlight_text.dart';

class ReaderTextDisplay extends StatefulWidget {
  final String text;
  final DisplaySettingsEntity settings;
  final Color fgColor;

  const ReaderTextDisplay({
    super.key,
    required this.text,
    required this.settings,
    required this.fgColor,
  });

  @override
  State<ReaderTextDisplay> createState() => _ReaderTextDisplayState();
}

class _ReaderTextDisplayState extends State<ReaderTextDisplay> {
  double _rulerY = 120.0;

  @override
  Widget build(BuildContext context) {
    const rulerH = 48.0;
    final s = widget.settings;
    final fg = widget.fgColor;
    final displayText = s.syllablesEnabled
        ? syllabify(widget.text)
        : widget.text;
    final paragraphs = displayText
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Stack(
      children: [
        MouseRegion(
          onHover: s.rulerEnabled
              ? (e) => setState(() => _rulerY = e.localPosition.dy)
              : null,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: SizedBox(
                width: 740,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: paragraphs
                      .map((para) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: WordHighlightText(
                              text: para.trim(),
                              style: applyDyslexiaFont(
                                font: s.font,
                                baseStyle: TextStyle(
                                  fontSize: s.fontSize,
                                  color: fg,
                                  height: s.lineSpacing,
                                  letterSpacing: s.letterSpacing,
                                  wordSpacing: s.wordSpacing,
                                ),
                              ),
                              maxWidth: 740,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        if (s.rulerEnabled)
          ReadingRuler(
            height: rulerH,
            foregroundColor: fg,
            rulerY: _rulerY,
            onPositionChanged: (y) => setState(() => _rulerY = y),
          ),
      ],
    );
  }
}
