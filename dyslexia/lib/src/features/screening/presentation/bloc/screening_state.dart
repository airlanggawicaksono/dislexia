import 'package:equatable/equatable.dart';

abstract class ScreeningState extends Equatable {
  const ScreeningState();
  @override
  List<Object?> get props => [];
}

class ScreeningInitial extends ScreeningState {}

class ScreeningLoading extends ScreeningState {
  final String? sessionId;
  final List<ChatMessage> messages;
  const ScreeningLoading({this.sessionId, this.messages = const []});

  @override
  List<Object?> get props => [sessionId, messages];
}

class ScreeningQuestionState extends ScreeningState {
  final String sessionId;
  final List<ChatMessage> messages;
  final bool isComplete;

  const ScreeningQuestionState({
    required this.sessionId,
    required this.messages,
    this.isComplete = false,
  });

  @override
  List<Object?> get props => [sessionId, messages, isComplete];
}

class ScreeningErrorState extends ScreeningState {
  final String message;
  final String? sessionId;
  final List<ChatMessage> messages;
  const ScreeningErrorState(this.message, {this.sessionId, this.messages = const []});

  @override
  List<Object?> get props => [message, sessionId, messages];
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isSummary;

  const ChatMessage({
    required this.text,
    this.isUser = false,
    this.isSummary = false,
  });
}
