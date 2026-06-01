import '../../domain/entities/reader_entity.dart';

class ReaderModel extends ReaderEntity {
  const ReaderModel({
    required super.text,
    super.sourceName,
    super.syllabifyEnabled,
    super.rulerPosition,
    super.rulerHeight,
  });

  factory ReaderModel.fromEntity(ReaderEntity e) => ReaderModel(
        text: e.text,
        sourceName: e.sourceName,
        syllabifyEnabled: e.syllabifyEnabled,
        rulerPosition: e.rulerPosition,
        rulerHeight: e.rulerHeight,
      );

  ReaderModel copyWith({
    String? text,
    String? sourceName,
    bool? syllabifyEnabled,
    double? rulerPosition,
    double? rulerHeight,
  }) {
    return ReaderModel(
      text: text ?? this.text,
      sourceName: sourceName ?? this.sourceName,
      syllabifyEnabled: syllabifyEnabled ?? this.syllabifyEnabled,
      rulerPosition: rulerPosition ?? this.rulerPosition,
      rulerHeight: rulerHeight ?? this.rulerHeight,
    );
  }
}
