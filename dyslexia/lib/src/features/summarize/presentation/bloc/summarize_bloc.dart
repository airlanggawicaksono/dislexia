import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/summarize_usecase.dart';
import 'summarize_event.dart';
import 'summarize_state.dart';

class SummarizeBloc extends Bloc<SummarizeEvent, SummarizeState> {
  final SummarizeUseCase _summarize;
  SummarizeBloc({required SummarizeUseCase summarize})
      : _summarize = summarize,
        super(SummarizeInitial()) {
    on<SummarizeTextEvent>(_onSummarize);
    on<ClearSummarizeEvent>((_, emit) => emit(SummarizeInitial()));
  }

  Future<void> _onSummarize(
      SummarizeTextEvent event, Emitter<SummarizeState> emit) async {
    emit(SummarizeLoading());
    // Streaming: append each chunk to the result and emit progressively so
    // the UI text grows live. History is saved backend-side on completion.
    final buffer = StringBuffer();
    var failed = false;
    await for (final chunk in _summarize(event.text, level: event.level)) {
      if (failed) break;
      chunk.fold(
        (failure) {
          failed = true;
          emit(SummarizeErrorState(failure.props.toString()));
        },
        (text) {
          buffer.write(text);
          emit(SummarizeResultState(
            inputText: event.text,
            result: buffer.toString(),
          ));
        },
      );
    }
    if (!failed) {
      emit(SummarizeResultState(
        inputText: event.text,
        result: buffer.toString(),
        // Stream is complete: this is the one emission the page should sync
        // its input controller from.
        streamComplete: true,
      ));
    }
  }
}
