import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/lens_frame_entity.dart';

class TextBoxPainter extends CustomPainter {
  final LensFrameEntity frame;

  static const double _minBoxHeight = 40.0;
  static const double _minBoxWidth = 80.0;

  const TextBoxPainter({required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    if (frame.imageSize == Size.zero) return;

    final double imgW =
        frame.isRotated ? frame.imageSize.height : frame.imageSize.width;
    final double imgH =
        frame.isRotated ? frame.imageSize.width : frame.imageSize.height;

    final double scale = math.max(size.width / imgW, size.height / imgH);
    final double dx = (imgW * scale - size.width) / 2;
    final double dy = (imgH * scale - size.height) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF4FC3F7);

    final paragraphs = frame.blocks.where((b) =>
        b.lineCount >= 2 &&
        b.boundingBox != null &&
        b.boundingBox!.height >= _minBoxHeight &&
        b.boundingBox!.width >= _minBoxWidth);

    for (final block in paragraphs) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          _transform(block.boundingBox!, scale, dx, dy),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  Rect _transform(Rect r, double scale, double dx, double dy) => Rect.fromLTRB(
        r.left * scale - dx,
        r.top * scale - dy,
        r.right * scale - dx,
        r.bottom * scale - dy,
      );

  @override
  bool shouldRepaint(TextBoxPainter old) => old.frame != frame;
}
