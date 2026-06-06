import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/personalize_result.dart';
import '../../domain/usecases/personalize_usecase.dart';
import 'personalize_event.dart';
import 'personalize_state.dart';

class PersonalizeBloc extends Bloc<PersonalizeEvent, PersonalizeState> {
  final PersonalizeUseCase _personalize;
  PersonalizeBloc({required PersonalizeUseCase personalize})
      : _personalize = personalize,
        super(PersonalizeInitial()) {
    on<PersonalizeTextEvent>(_onPersonalize);
    on<ClearPersonalizeEvent>((_, emit) => emit(PersonalizeInitial()));
  }

  Future<void> _onPersonalize(
      PersonalizeTextEvent event, Emitter<PersonalizeState> emit) async {
    emit(PersonalizeLoading());
    final result = await _personalize(event.text);
    result.fold(
      (failure) => emit(PersonalizeErrorState(failure.props.toString())),
      (PersonalizeResult success) =>
          emit(PersonalizeResultState(inputText: event.text, result: success.text)),
    );
  }
}
