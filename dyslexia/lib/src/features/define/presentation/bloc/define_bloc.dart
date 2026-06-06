import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/define_result.dart';
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
    final result = await _define(event.text);
    result.fold(
      (failure) => emit(DefineErrorState(failure.props.toString())),
      (DefineResult success) =>
          emit(DefineResultState(inputText: event.text, result: success.text)),
    );
  }
}
