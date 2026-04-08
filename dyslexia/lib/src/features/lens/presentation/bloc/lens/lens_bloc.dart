import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/entities/document_entity.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/utils/failure_converter.dart';
import '../../../domain/usecases/capture_text_usecase.dart';

part 'lens_event.dart';
part 'lens_state.dart';

class LensBloc extends Bloc<LensEvent, LensState> {
  final CaptureTextUseCase _captureText;

  LensBloc(this._captureText) : super(LensInitialState()) {
    on<CaptureTextEvent>(_onCapture);
  }

  Future<void> _onCapture(
      CaptureTextEvent event, Emitter<LensState> emit) async {
    emit(LensLoadingState());
    final result = await _captureText.call(NoParams());
    result.fold(
      (l) => emit(LensFailureState(mapFailureToMessage(l))),
      (r) => emit(LensSuccessState(r)),
    );
  }
}
