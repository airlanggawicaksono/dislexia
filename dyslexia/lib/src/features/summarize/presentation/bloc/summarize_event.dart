import 'package:equatable/equatable.dart';

abstract class SummarizeEvent extends Equatable {
  const SummarizeEvent();
  @override
  List<Object?> get props => [];
}

class SummarizeTextEvent extends SummarizeEvent {
  final String text;
  const SummarizeTextEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class ClearSummarizeEvent extends SummarizeEvent {}
