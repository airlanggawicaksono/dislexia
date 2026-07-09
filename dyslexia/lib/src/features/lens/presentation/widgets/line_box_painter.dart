import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/recognized_frame.dart';

/// Draws a rounded box over each recognised line, mapping ML Kit's
/// image-space boxes onto the preview. The X/Y translation follows the
/// canonical google_mlkit example's coordinate translator (rotation +
/// front-camera mirror aware). Assumes the preview fills the paint area
/// (BoxFit.fill); may need per-device tuning if the preview is letterboxed.
class LineBoxPainter extends CustomPainter {
  final RecognizedFrame frame;

  const LineBoxPainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.imageSize == Size.zero || frame.lines.isEmpty) return;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF4FC3F7);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x224FC3F7);

    for (final line in frame.lines) {
      final rect = _mapRect(line.boundingBox, size).inflate(3);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);
    }
  }

  /// Map an ML Kit box (in the *upright* image coordinate space) onto the
  /// preview using the SAME BoxFit.cover transform the preview widget uses
  /// (uniform scale = max, centred), so boxes stay glued to the text on
  /// both platforms. When the sensor rotation is 90/270 the upright image
  /// dimensions are swapped.
  Rect _mapRect(Rect box, Size canvasSize) {
    final swapped =
        frame.rotationDegrees == 90 || frame.rotationDegrees == 270;
    final imgW = swapped ? frame.imageSize.height : frame.imageSize.width;
    final imgH = swapped ? frame.imageSize.width : frame.imageSize.height;
    if (imgW == 0 || imgH == 0) return Rect.zero;

    final scale =
        math.max(canvasSize.width / imgW, canvasSize.height / imgH);
    final dx = (imgW * scale - canvasSize.width) / 2;
    final dy = (imgH * scale - canvasSize.height) / 2;

    var left = box.left * scale - dx;
    var right = box.right * scale - dx;
    final top = box.top * scale - dy;
    final bottom = box.bottom * scale - dy;

    if (frame.isFrontCamera) {
      final mirroredLeft = canvasSize.width - right;
      final mirroredRight = canvasSize.width - left;
      left = mirroredLeft;
      right = mirroredRight;
    }
    return Rect.fromLTRB(
      math.min(left, right),
      math.min(top, bottom),
      math.max(left, right),
      math.max(top, bottom),
    );
  }

  @override
  bool shouldRepaint(LineBoxPainter oldDelegate) => oldDelegate.frame != frame;
}
