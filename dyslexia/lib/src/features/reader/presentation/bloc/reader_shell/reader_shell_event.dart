import 'package:equatable/equatable.dart';

abstract class ReaderShellEvent extends Equatable {
  const ReaderShellEvent();

  @override
  List<Object?> get props => [];
}

/// Load a piece of text into the reader. Pass an empty/whitespace
/// string to dismiss the reader and fall back to the landing content.
class LoadTextEvent extends ReaderShellEvent {
  final String text;
  final String? source;

  const LoadTextEvent(this.text, {this.source});

  @override
  List<Object?> get props => [text, source];
}

/// Clear whatever is loaded and show the landing content again.
class ClearTextEvent extends ReaderShellEvent {
  const ClearTextEvent();
}

/// Update PDF processing progress. When [current] >= [total] the
/// overlay is hidden.
class SetPdfProgressEvent extends ReaderShellEvent {
  final int current;
  final int total;

  const SetPdfProgressEvent({required this.current, required this.total});

  @override
  List<Object?> get props => [current, total];
}

class ClearPdfProgressEvent extends ReaderShellEvent {
  const ClearPdfProgressEvent();
}
