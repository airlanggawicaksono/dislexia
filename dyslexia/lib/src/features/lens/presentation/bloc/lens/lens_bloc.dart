import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/entities/document_entity.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/utils/failure_converter.dart';
import '../../../domain/entities/lens_frame_entity.dart';
import '../../../domain/usecases/analyze_frame_usecase.dart';
import '../../../domain/usecases/capture_text_usecase.dart';

part 'lens_event.dart';
part 'lens_state.dart';

class LensBloc extends Bloc<LensEvent, LensState> {
  final CaptureTextUseCase _captureText;
  final AnalyzeFrameUseCase _analyzeFrame;
  bool _isAnalyzing = false;

  LensBloc(this._captureText, this._analyzeFrame) : super(LensInitialState()) {
    on<CaptureTextEvent>(_onCapture);
    on<AnalyzeFrameEvent>(_onAnalyzeFrame);
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

  Future<void> _onAnalyzeFrame(
      AnalyzeFrameEvent event, Emitter<LensState> emit) async {
    if (_isAnalyzing) return;
    _isAnalyzing = true;
    try {
      final result = await _analyzeFrame.call(AnalyzeFrameParams(event.image));
      result.fold(
        (_) {}, // silently drop frame errors
        (frame) => emit(LensLiveState(frame)),
      );
    } finally {
      _isAnalyzing = false;
    }
  }
}
