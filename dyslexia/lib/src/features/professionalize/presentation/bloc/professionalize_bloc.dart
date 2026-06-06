import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/professionalize_result.dart';
import '../../domain/usecases/professionalize_usecase.dart';
import 'professionalize_event.dart';
import 'professionalize_state.dart';

class ProfessionalizeBloc extends Bloc<ProfessionalizeEvent, ProfessionalizeState> {
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
    final result = await _professionalize(event.text);
    result.fold(
      (failure) => emit(ProfessionalizeErrorState(failure.props.toString())),
      (ProfessionalizeResult success) =>
          emit(ProfessionalizeResultState(inputText: event.text, result: success.text)),
    );
  }
}
