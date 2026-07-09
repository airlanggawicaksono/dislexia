import 'dart:async';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/entities/document_entity.dart';
import '../../../../../core/errors/failures.dart';
import '../../../domain/entities/recognized_frame.dart';
import '../../../domain/usecases/capture_text_usecase.dart';
import '../../../domain/usecases/lens_preview_usecase.dart';
import '../../../domain/usecases/start_lens_usecase.dart';
import '../../../domain/usecases/stop_lens_usecase.dart';
import '../../../domain/usecases/watch_frames_usecase.dart';

part 'lens_event.dart';
part 'lens_state.dart';

class LensBloc extends Bloc<LensEvent, LensState> {
  final StartLensUseCase _start;
  final StopLensUseCase _stop;
  final WatchFramesUseCase _watch;
  final LensPreviewUseCase _preview;
  final CaptureTextUseCase _capture;

  StreamSubscription<RecognizedFrame>? _sub;

  /// The active camera controller for the preview widget (null until live).
  CameraController? get previewController => _preview();

  LensBloc(
    this._start,
    this._stop,
    this._watch,
    this._preview,
    this._capture,
  ) : super(LensInitialState()) {
    on<StartLensEvent>(_onStart);
    on<StopLensEvent>(_onStop);
    on<CaptureTextEvent>(_onCapture);
    on<_FrameReceivedEvent>(_onFrame);
  }

  Future<void> _onStart(StartLensEvent event, Emitter<LensState> emit) async {
    emit(LensStartingState());
    final result = await _start();
    result.fold(
      (failure) => emit(LensFailureState(
        failure is CameraFailure ? failure.message : 'Unable to start camera',
      )),
      (_) {
        _sub?.cancel();
        _sub = _watch().listen((frame) => add(_FrameReceivedEvent(frame)));
        // Emit an empty live state so the preview renders immediately,
        // before the first OCR frame lands.
        emit(LensLiveState(RecognizedFrame.empty));
      },
    );
  }

  void _onFrame(_FrameReceivedEvent event, Emitter<LensState> emit) {
    emit(LensLiveState(event.frame));
  }

  Future<void> _onStop(StopLensEvent event, Emitter<LensState> emit) async {
    await _sub?.cancel();
    _sub = null;
    await _stop();
    emit(LensInitialState());
  }

  Future<void> _onCapture(CaptureTextEvent event, Emitter<LensState> emit) async {
    // OCR a fresh full-res still (much more accurate than the live frames).
    final result = await _capture();
    result.fold(
      (_) {}, // capture found nothing / failed — stay live, let user retry
      (text) => emit(LensSuccessState(DocumentEntity(
        id: const Uuid().v4(),
        text: text,
        sourceName: 'Lens',
      ))),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _stop();
    return super.close();
  }
}
