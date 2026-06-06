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

  const SummarizeResultState({required this.inputText, required this.result});

  @override
  List<Object?> get props => [inputText, result];
}

class SummarizeErrorState extends SummarizeState {
  final String message;
  const SummarizeErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
