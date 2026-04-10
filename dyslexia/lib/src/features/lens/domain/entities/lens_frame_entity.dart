import 'dart:ui';

import 'package:equatable/equatable.dart';

class RecognizedBlockEntity extends Equatable {
  final Rect? boundingBox;
  final int lineCount;

  const RecognizedBlockEntity({
    required this.boundingBox,
    required this.lineCount,
  });

  @override
  List<Object?> get props => [boundingBox, lineCount];
}

class LensFrameEntity extends Equatable {
  final String text;
  final List<RecognizedBlockEntity> blocks;
  final Size imageSize;
  final bool isRotated;

  const LensFrameEntity({
    required this.text,
    required this.blocks,
    required this.imageSize,
    required this.isRotated,
  });

  @override
  List<Object?> get props => [text, blocks, imageSize, isRotated];
}
