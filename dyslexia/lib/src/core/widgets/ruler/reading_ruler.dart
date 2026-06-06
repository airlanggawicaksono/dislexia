import 'package:flutter/material.dart';

/// Horizontal reading ruler with drag handle. Shown on top of the text
/// in every feature that respects `DisplaySettingsBloc.rulerEnabled`.
class ReadingRuler extends StatelessWidget {
  final double height;
  final Color foregroundColor;
  final double rulerY;
  final ValueChanged<double> onPositionChanged;

  const ReadingRuler({
    super.key,
    required this.height,
    required this.foregroundColor,
    required this.rulerY,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: (rulerY - height / 2).clamp(0.0, MediaQuery.of(context).size.height - height),
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
                child: SizedBox(height: height, width: 120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
