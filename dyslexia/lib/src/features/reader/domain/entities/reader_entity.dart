import 'package:equatable/equatable.dart';

class ReaderEntity extends Equatable {
  final String text;
  final String? sourceName;
  final bool syllabifyEnabled;
  final double rulerPosition;
  final double rulerHeight;

  const ReaderEntity({
    required this.text,
    this.sourceName,
    this.syllabifyEnabled = true,
    this.rulerPosition = 0.0,
    this.rulerHeight = 48.0,
  });

  ReaderEntity copyWith({
    String? text,
    String? sourceName,
    bool? syllabifyEnabled,
    double? rulerPosition,
    double? rulerHeight,
  }) {
    return ReaderEntity(
      text: text ?? this.text,
      sourceName: sourceName ?? this.sourceName,
      syllabifyEnabled: syllabifyEnabled ?? this.syllabifyEnabled,
      rulerPosition: rulerPosition ?? this.rulerPosition,
      rulerHeight: rulerHeight ?? this.rulerHeight,
    );
  }

  @override
  List<Object?> get props => [text, sourceName, syllabifyEnabled, rulerPosition, rulerHeight];
}
