import 'dart:ui';

import 'package:equatable/equatable.dart';

/// A single recognised line of text with its bounding box, in the
/// coordinate space of the (rotation-applied) camera image that produced
/// it. The painter maps [boundingBox] onto the preview widget.
class RecognizedLine extends Equatable {
  final String text;
  final Rect boundingBox;

  const RecognizedLine({required this.text, required this.boundingBox});

  @override
  List<Object?> get props => [text, boundingBox];
}
