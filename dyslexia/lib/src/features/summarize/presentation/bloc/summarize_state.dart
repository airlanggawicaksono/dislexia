import 'package:equatable/equatable.dart';

abstract class SummarizeState extends Equatable {
  const SummarizeState();
  @override
  List<Object?> get props => [];
}

class SummarizeInitial extends SummarizeState {}

class SummarizeLoading extends SummarizeState {}

class SummarizeResultState extends SummarizeState {
  final String inputText;
  final String result;

  /// True only on the FINAL emission of a completed stream. While SSE chunks
  /// are still arriving it is false, so the page knows to keep the input
  /// controller untouched until the whole result is ready (per-chunk writes
  /// caused a controller->rebuild->write loop / stack overflow).
  final bool streamComplete;

  const SummarizeResultState({
    required this.inputText,
    required this.result,
    this.streamComplete = false,
  });

  @override
  List<Object?> get props => [inputText, result, streamComplete];
}

class SummarizeErrorState extends SummarizeState {
  final String message;
  const SummarizeErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
