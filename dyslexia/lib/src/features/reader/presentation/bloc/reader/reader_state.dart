import 'package:equatable/equatable.dart';
import '../../../domain/entities/reader_entity.dart';

class ReaderState extends Equatable {
  final ReaderEntity? reader;
  final String displayText;

  const ReaderState({this.reader, this.displayText = ''});

  ReaderState copyWith({ReaderEntity? reader, String? displayText}) {
    return ReaderState(
      reader: reader ?? this.reader,
      displayText: displayText ?? this.displayText,
    );
  }

  @override
  List<Object?> get props => [reader, displayText];
}
