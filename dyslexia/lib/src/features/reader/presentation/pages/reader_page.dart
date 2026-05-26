import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/font_utils.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../display_settings/presentation/theme/display_colors.dart';
import '../bloc/reader/reader_bloc.dart';
import '../bloc/reader/reader_event.dart';
import '../bloc/reader/reader_state.dart';

class _WordHighlightText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;

  const _WordHighlightText({
    required this.text,
    required this.style,
    required this.maxWidth,
  });

  @override
  State<_WordHighlightText> createState() => _WordHighlightTextState();
}

class _WordHighlightTextState extends State<_WordHighlightText> {
  TextSelection _selection = const TextSelection.collapsed(offset: -1);

  void _updateSelection(Offset localPosition) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: widget.maxWidth);

    final index = painter.getPositionForOffset(localPosition).offset;

    if (index >= widget.text.length ||
        RegExp(r'\s').hasMatch(widget.text[index])) {
      if (_selection.isValid) {
        setState(() => _selection = const TextSelection.collapsed(offset: -1));
      }
      return;
    }

    int start = index;
    while (start > 0 && !RegExp(r'\s').hasMatch(widget.text[start - 1])) {
      start--;
    }

    int end = index;
    while (
        end < widget.text.length && !RegExp(r'\s').hasMatch(widget.text[end])) {
      end++;
    }

    final newSelection = TextSelection(baseOffset: start, extentOffset: end);
    if (newSelection != _selection) {
      setState(() {
        _selection = newSelection;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _updateSelection(event.localPosition),
      onExit: (event) {
        if (_selection.isValid) {
          setState(() {
            _selection = const TextSelection.collapsed(offset: -1);
          });
        }
      },
      child: Builder(builder: (context) {
        if (!_selection.isValid) {
          return RichText(
              text: TextSpan(text: widget.text, style: widget.style));
        }

        final beforeText = widget.text.substring(0, _selection.start);
        final selectedText =
            widget.text.substring(_selection.start, _selection.end);
        final afterText = widget.text.substring(_selection.end);

        return RichText(
          text: TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: beforeText),
              TextSpan(
                text: selectedText,
                style: TextStyle(
                  backgroundColor: widget.style.color!.withOpacity(0.12),
                ),
              ),
              TextSpan(text: afterText),
            ],
          ),
        );
      }),
    );
  }
}

class ReaderPage extends StatefulWidget {
  final String text;
  final String? sourceName;
  final VoidCallback? onBack;
  const ReaderPage(
      {super.key, required this.text, this.sourceName, this.onBack});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  double _rulerY = 120.0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DisplaySettingsBloc, DisplaySettingsState>(
      listenWhen: (prev, curr) =>
          prev.settings.syllablesEnabled != curr.settings.syllablesEnabled,
      listener: (context, state) {
        context.read<ReaderBloc>().add(ToggleSyllabifyEvent());
      },
      child: BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
        builder: (context, displayState) {
          final s = displayState.settings;
          final bg = bgColor(s.colorTheme);
          final fg = fgColor(s.colorTheme);
          const rulerH = 48.0;

          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: fg),
                onPressed:
                    widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
              title: Text(widget.sourceName ?? 'Reader',
                  style: TextStyle(color: fg)),
              actions: [
                IconButton(
                  icon: Icon(
                    s.syllablesEnabled
                        ? Icons.text_fields
                        : Icons.text_fields_outlined,
                    color: fg,
                  ),
                  tooltip: 'Toggle syllabification',
                  onPressed: () => context
                      .read<DisplaySettingsBloc>()
                      .add(ToggleSyllablesEvent()),
                ),
              ],
            ),
            body: Stack(
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
                        child: BlocBuilder<ReaderBloc, ReaderState>(
                          builder: (context, state) {
                            final displayText = state.displayText.isEmpty
                                ? widget.text
                                : state.displayText;
                            final paragraphs = displayText
                                .split('\n\n')
                                .where((p) => p.trim().isNotEmpty)
                                .toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: paragraphs
                                  .map((para) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 20),
                                        child: _WordHighlightText(
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
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                if (s.rulerEnabled)
                  _ReadingRuler(
                    height: rulerH,
                    foregroundColor: fg,
                    rulerY: _rulerY,
                    onPositionChanged: (y) => setState(() => _rulerY = y),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReadingRuler extends StatelessWidget {
  final double height;
  final Color foregroundColor;
  final double rulerY;
  final ValueChanged<double> onPositionChanged;
  const _ReadingRuler({
    required this.height,
    required this.foregroundColor,
    required this.rulerY,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height;
    return Positioned(
      top: rulerY.clamp(0.0, maxH - height),
      left: 0,
      right: 0,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            IgnorePointer(
              child: Container(
                width: double.infinity,
                height: height,
                decoration: BoxDecoration(
                  color: foregroundColor.withValues(alpha: 0.06),
                  border: Border(
                    top: BorderSide(
                        color: foregroundColor.withValues(alpha: 0.4),
                        width: 1.5),
                    bottom: BorderSide(
                        color: foregroundColor.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onVerticalDragStart: (d) =>
                    onPositionChanged(rulerY + d.localPosition.dy - height / 2),
                onVerticalDragUpdate: (d) =>
                    onPositionChanged(rulerY + d.delta.dy),
                child: SizedBox(
                  height: height,
                  width: 120,
                  child: Center(
                    child: Container(
                      height: 4,
                      width: 60,
                      decoration: BoxDecoration(
                        color: foregroundColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
