import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Horizontal reading ruler with drag handle and keyboard control.
/// Shown on top of the text in every feature that respects
/// `DisplaySettingsBloc.rulerEnabled`.
///
/// Keyboard: tab to focus the ruler, then ArrowUp/ArrowDown to nudge it,
/// PageUp/PageDown for larger jumps.
class ReadingRuler extends StatefulWidget {
  final double height;
  final double rulerY;
  final ValueChanged<double> onPositionChanged;

  const ReadingRuler({
    super.key,
    required this.height,
    required this.rulerY,
    required this.onPositionChanged,
  });

  @override
  State<ReadingRuler> createState() => _ReadingRulerState();
}

class _ReadingRulerState extends State<ReadingRuler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final key = event.logicalKey;
    double? delta;
    if (key == LogicalKeyboardKey.arrowUp) {
      delta = -16;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      delta = 16;
    } else if (key == LogicalKeyboardKey.pageUp) {
      delta = -96;
    } else if (key == LogicalKeyboardKey.pageDown) {
      delta = 96;
    }
    if (delta == null) return false;
    widget.onPositionChanged(widget.rulerY + delta);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final borderColor = const Color(0xFFC8A000);

    return Positioned(
      top: (widget.rulerY - widget.height / 2)
          .clamp(0.0, MediaQuery.of(context).size.height - widget.height),
      left: 0,
      right: 0,
      child: Semantics(
        label: 'Reading ruler. Use arrow keys to move it up or down.',
        button: true,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) =>
              _handleKey(event) ? KeyEventResult.handled : KeyEventResult.ignored,
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                IgnorePointer(
                  child: Container(
                    width: double.infinity,
                    height: widget.height,
                    decoration: BoxDecoration(
                      // Match React web: yellow/amber ruler color
                      color: const Color(0xFFFDD200).withValues(alpha: 0.13),
                      border: Border(
                        top: BorderSide(
                            color: borderColor.withValues(
                                alpha: focused ? 1.0 : 0.25),
                            width: focused ? 2 : 1),
                        bottom: BorderSide(
                            color: borderColor.withValues(
                                alpha: focused ? 1.0 : 0.25),
                            width: focused ? 2 : 1),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragStart: (d) => widget.onPositionChanged(
                          widget.rulerY + d.localPosition.dy - widget.height / 2),
                      onVerticalDragUpdate: (d) =>
                          widget.onPositionChanged(widget.rulerY + d.delta.dy),
                      child: SizedBox(
                        height: widget.height,
                        width: 48,
                        // Visible grip so the ruler is discoverable + draggable on
                        // touch (no hover to reveal it). Narrow hit area (48px =
                        // the grip itself) so it doesn't block hover/selection
                        // on the words underneath.
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: borderColor.withValues(
                                  alpha: focused ? 1.0 : 0.7),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
