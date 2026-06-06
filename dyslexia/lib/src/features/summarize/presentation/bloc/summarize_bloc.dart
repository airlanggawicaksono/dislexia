import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/summarize_result.dart';
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
    final result = await _summarize(event.text);
    result.fold(
      (failure) => emit(SummarizeErrorState(failure.props.toString())),
      (SummarizeResult success) =>
          emit(SummarizeResultState(inputText: event.text, result: success.text)),
    );
  }
}
