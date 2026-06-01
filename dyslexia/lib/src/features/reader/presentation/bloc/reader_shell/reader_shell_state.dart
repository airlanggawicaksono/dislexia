import 'package:equatable/equatable.dart';

/// Lightweight view-state for the reader main column.
///
/// This is deliberately separate from [ReaderState] (the heavy
/// syllabification / ruler / display model owned by [ReaderBloc]).
/// [ReaderShellState] is the minimum the shell needs to know in order
/// to render the right content + overlay: which text is currently
/// loaded, its source label, whether the reader page should be shown,
/// and any in-flight PDF progress.
class ReaderShellState extends Equatable {
  final String text;
  final String? source;
  final bool showReader;
  final ({int current, int total})? pdfProgress;

  const ReaderShellState({
    this.text = '',
    this.source,
    this.showReader = false,
    this.pdfProgress,
  });

  static const empty = ReaderShellState();

  ReaderShellState copyWith({
    String? text,
    String? source,
    bool? showReader,
    Object? pdfProgress = _sentinel,
  }) {
    return ReaderShellState(
      text: text ?? this.text,
      source: source ?? this.source,
      showReader: showReader ?? this.showReader,
      pdfProgress: identical(pdfProgress, _sentinel)
          ? this.pdfProgress
          : pdfProgress as ({int current, int total})?,
    );
  }

  @override
  List<Object?> get props => [text, source, showReader, pdfProgress];
}

const Object _sentinel = Object();
