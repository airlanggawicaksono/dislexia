import 'dart:ui';

import 'package:equatable/equatable.dart';

import 'recognized_line.dart';

/// One processed camera frame: the recognised lines plus everything the
/// overlay painter needs to place their boxes correctly (raw image size,
/// how the sensor was rotated, and which camera took it).
class RecognizedFrame extends Equatable {
  final List<RecognizedLine> lines;

  /// All line text joined, newest stabilised read. Shown in the panel.
  final String fullText;

  /// Size of the raw camera image (before rotation is applied).
  final Size imageSize;

  /// Sensor rotation applied by ML Kit: 0 / 90 / 180 / 270.
  final int rotationDegrees;

  /// Front camera frames are mirrored — the painter flips X for them.
  final bool isFrontCamera;

  const RecognizedFrame({
    required this.lines,
    required this.fullText,
    required this.imageSize,
    required this.rotationDegrees,
    required this.isFrontCamera,
  });

  static const empty = RecognizedFrame(
    lines: [],
    fullText: '',
    imageSize: Size.zero,
    rotationDegrees: 0,
    isFrontCamera: false,
  );

  RecognizedFrame copyWith({List<RecognizedLine>? lines, String? fullText}) {
    return RecognizedFrame(
      lines: lines ?? this.lines,
      fullText: fullText ?? this.fullText,
      imageSize: imageSize,
      rotationDegrees: rotationDegrees,
      isFrontCamera: isFrontCamera,
    );
  }

  @override
  List<Object?> get props =>
      [lines, fullText, imageSize, rotationDegrees, isFrontCamera];
}
