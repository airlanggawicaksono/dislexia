import 'package:flutter/material.dart';

/// Horizontal reading ruler with drag handle. Shown on top of the text
/// in every feature that respects `DisplaySettingsBloc.rulerEnabled`.
class ReadingRuler extends StatelessWidget {
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
                  // Match React web: yellow/amber ruler color
                  color: const Color(0xFFFDD200).withValues(alpha: 0.13),
                  border: Border(
                    top: BorderSide(
                        color: const Color(0xFFC8A000).withValues(alpha: 0.25),
                        width: 1),
                    bottom: BorderSide(
                        color: const Color(0xFFC8A000).withValues(alpha: 0.25),
                        width: 1),
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
