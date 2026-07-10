import 'package:equatable/equatable.dart';

import 'screening_state.dart';

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

/// Rehydrate an incomplete session so the user can continue it. The messages
/// are replayed from history; further replies use [sessionId] server-side.
class ResumeScreeningEvent extends ScreeningEvent {
  final String sessionId;
  final List<ChatMessage> messages;
  const ResumeScreeningEvent(this.sessionId, this.messages);

  @override
  List<Object?> get props => [sessionId, messages];
}

class ResetScreeningEvent extends ScreeningEvent {}
