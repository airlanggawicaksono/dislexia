import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/professionalize_usecase.dart';
import 'professionalize_event.dart';
import 'professionalize_state.dart';

class ProfessionalizeBloc
    extends Bloc<ProfessionalizeEvent, ProfessionalizeState> {
  final ProfessionalizeUseCase _professionalize;
  ProfessionalizeBloc({required ProfessionalizeUseCase professionalize})
      : _professionalize = professionalize,
        super(ProfessionalizeInitial()) {
    on<ProfessionalizeTextEvent>(_onProfessionalize);
    on<ClearProfessionalizeEvent>((_, emit) => emit(ProfessionalizeInitial()));
  }

  Future<void> _onProfessionalize(
      ProfessionalizeTextEvent event, Emitter<ProfessionalizeState> emit) async {
    emit(ProfessionalizeLoading());
    // Streaming: append each chunk to the result and emit progressively so
    // the UI text grows live. History is saved backend-side on completion.
    final buffer = StringBuffer();
    var failed = false;
    await for (final chunk in _professionalize(
      event.text,
      recipientName: event.recipientName,
      senderName: event.senderName,
    )) {
      if (failed) break;
      chunk.fold(
        (failure) {
          failed = true;
          emit(ProfessionalizeErrorState(failure.props.toString()));
        },
        (text) {
          buffer.write(text);
          emit(ProfessionalizeResultState(
            inputText: event.text,
            result: buffer.toString(),
          ));
        },
      );
    }
    if (!failed) {
      emit(ProfessionalizeResultState(
        inputText: event.text,
        result: buffer.toString(),
        // Stream is complete: this is the one emission the page should sync
        // its input controller from.
        streamComplete: true,
      ));
    }
  }
}
