import 'package:equatable/equatable.dart';

import '../../domain/entities/summary_level.dart';

abstract class SummarizeEvent extends Equatable {
  const SummarizeEvent();
  @override
  List<Object?> get props => [];
}

class SummarizeTextEvent extends SummarizeEvent {
  final String text;
  final SummaryLevel? level;
  const SummarizeTextEvent(this.text, {this.level});

  @override
  List<Object?> get props => [text, level];
}

class ClearSummarizeEvent extends SummarizeEvent {}
