import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/define_usecase.dart';
import 'define_event.dart';
import 'define_state.dart';

class DefineBloc extends Bloc<DefineEvent, DefineState> {
  final DefineUseCase _define;
  DefineBloc({required DefineUseCase define})
      : _define = define,
        super(DefineInitial()) {
    on<DefineTextEvent>(_onDefine);
    on<ClearDefineEvent>((_, emit) => emit(DefineInitial()));
  }

  Future<void> _onDefine(
      DefineTextEvent event, Emitter<DefineState> emit) async {
    emit(DefineLoading());
    // Streaming: append each chunk to the result and emit progressively so
    // the UI text grows live. History is saved backend-side on completion.
    final buffer = StringBuffer();
    var failed = false;
    await for (final chunk in _define(event.text, level: event.level)) {
      if (failed) break;
      chunk.fold(
        (failure) {
          failed = true;
          emit(DefineErrorState(failure.props.toString()));
        },
        (text) {
          buffer.write(text);
          emit(DefineResultState(
            inputText: event.text,
            result: buffer.toString(),
          ));
        },
      );
    }
    if (!failed) {
      emit(DefineResultState(
        inputText: event.text,
        result: buffer.toString(),
        // Stream is complete: this is the one emission the page should sync
        // its input controller from.
        streamComplete: true,
      ));
    }
  }
}
