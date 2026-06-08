import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/screening_result.dart';
import '../../domain/usecases/screening_usecase.dart';
import 'screening_event.dart';
import 'screening_state.dart';

class ScreeningBloc extends Bloc<ScreeningEvent, ScreeningState> {
  final ScreeningUseCase _screening;
  ScreeningBloc({required ScreeningUseCase screening})
      : _screening = screening,
        super(ScreeningInitial()) {
    on<StartScreeningEvent>(_onStart);
    on<ReplyScreeningEvent>(_onReply);
    on<ResetScreeningEvent>((_, emit) => emit(ScreeningInitial()));
  }

  Future<void> _onStart(
      StartScreeningEvent event, Emitter<ScreeningState> emit) async {
    emit(ScreeningLoading());
    final result = await _screening.start();
    result.fold(
      (failure) => emit(ScreeningErrorState(failure.props.toString())),
      (ScreeningResult success) => emit(ScreeningQuestionState(
        sessionId: success.sessionId,
        isComplete: success.isComplete,
        messages: [ChatMessage(text: success.text)],
      )),
    );
  }

  Future<void> _onReply(
      ReplyScreeningEvent event, Emitter<ScreeningState> emit) async {
    final current = state;
    final sessionId = current is ScreeningQuestionState
        ? current.sessionId
        : current is ScreeningLoading
            ? current.sessionId
            : null;
    if (sessionId == null) return;

    final currentMessages = current is ScreeningQuestionState
        ? current.messages
        : <ChatMessage>[];

    final updatedMessages = [
      ...currentMessages,
      ChatMessage(text: event.text, isUser: true),
    ];

    emit(ScreeningLoading(sessionId: sessionId, messages: updatedMessages));

    final result = await _screening.reply(event.text, sessionId);
    result.fold(
      (failure) => emit(ScreeningErrorState(
        failure.props.toString(),
        sessionId: sessionId,
        messages: updatedMessages,
      )),
      (ScreeningResult success) {
        final newMessages = [
          ...updatedMessages,
          ChatMessage(
            text: success.text,
            isSummary: success.isComplete,
          ),
        ];
        emit(ScreeningQuestionState(
          sessionId: success.sessionId,
          messages: newMessages,
          isComplete: success.isComplete,
        ));
      },
    );
  }
}
