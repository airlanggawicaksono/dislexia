import 'package:flutter/material.dart';

class WordHighlightText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;

  const WordHighlightText({
    super.key,
    required this.text,
    required this.style,
    required this.maxWidth,
  });

  @override
  State<WordHighlightText> createState() => _WordHighlightTextState();
}

class _WordHighlightTextState extends State<WordHighlightText> {
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
    while (end < widget.text.length &&
        !RegExp(r'\s').hasMatch(widget.text[end])) {
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
