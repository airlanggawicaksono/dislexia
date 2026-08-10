import 'package:equatable/equatable.dart';

abstract class ProfessionalizeState extends Equatable {
  const ProfessionalizeState();
  @override
  List<Object?> get props => [];
}

class ProfessionalizeInitial extends ProfessionalizeState {}

class ProfessionalizeLoading extends ProfessionalizeState {}

class ProfessionalizeResultState extends ProfessionalizeState {
  final String inputText;
  final String result;

  /// True only on the FINAL emission of a completed stream. While SSE chunks
  /// are still arriving it is false, so the page knows to keep the input
  /// controller untouched until the whole result is ready (per-chunk writes
  /// caused a controller->rebuild->write loop / stack overflow).
  final bool streamComplete;

  const ProfessionalizeResultState({
    required this.inputText,
    required this.result,
    this.streamComplete = false,
  });

  @override
  List<Object?> get props => [inputText, result, streamComplete];
}

class ProfessionalizeErrorState extends ProfessionalizeState {
  final String message;
  const ProfessionalizeErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
