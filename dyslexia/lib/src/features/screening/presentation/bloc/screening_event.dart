import 'package:equatable/equatable.dart';

abstract class ScreeningEvent extends Equatable {
  const ScreeningEvent();
  @override
  List<Object?> get props => [];
}

class StartScreeningEvent extends ScreeningEvent {}

class ReplyScreeningEvent extends ScreeningEvent {
  final String text;
  const ReplyScreeningEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class ResetScreeningEvent extends ScreeningEvent {}
