import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import '../../features/display_settings/domain/entities/display_settings_entity.dart';
import '../../features/reader/data/datasources/local_syllabifier_datasource.dart';
import '../utils/font_utils.dart';
import 'ruler/reading_ruler.dart';
import 'word_highlight_text.dart';

class ReaderTextDisplay extends StatefulWidget {
  final String text;
  final DisplaySettingsEntity settings;
  final Color fgColor;
  final Color? bgColor;
  final bool scrollable;

  const ReaderTextDisplay({
    super.key,
    required this.text,
    required this.settings,
    required this.fgColor,
    this.bgColor,
    this.scrollable = true,
  });

  @override
  State<ReaderTextDisplay> createState() => _ReaderTextDisplayState();
}

class _ReaderTextDisplayState extends State<ReaderTextDisplay> {
  double _rulerY = 120.0;
  bool _isHovering = false;

  /// Touch platforms have no mouse hover, so the ruler must be shown
  /// persistently (and dragged) rather than following the cursor.
  bool get _isTouch =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    const rulerH = 48.0;
    final s = widget.settings;
    final fg = widget.fgColor;
    final localSyllabifier = LocalSyllabifierDatasource();
    final displayText = s.syllablesEnabled
        ? localSyllabifier.syllabify(widget.text)
        : widget.text;
    final paragraphs = displayText
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final contentWidth = maxW < 800.0 ? maxW - 32 : 740.0.clamp(400.0, maxW - 64);
        return ColoredBox(
          color: widget.bgColor ?? Colors.transparent,
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovering = true),
                  onExit: (_) => setState(() => _isHovering = false),
                  onHover: s.rulerEnabled
                      ? (e) => setState(() => _rulerY = e.localPosition.dy)
                      : null,
                  child: widget.scrollable
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: _content(contentWidth, paragraphs, fg, s),
                        )
                      : _content(contentWidth, paragraphs, fg, s),
                ),
                // Desktop: follow the cursor (hover). Touch: show it
                // persistently so it can be dragged — there is no hover.
                if (s.rulerEnabled && (_isHovering || _isTouch))
                  ReadingRuler(
                    height: rulerH,
                    rulerY: _rulerY,
                    onPositionChanged: (y) => setState(() => _rulerY = y),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content(double contentWidth, List<String> paragraphs, Color fg, DisplaySettingsEntity s) {
    return Center(
      child: SizedBox(
        width: contentWidth,
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
                      maxWidth: contentWidth,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
