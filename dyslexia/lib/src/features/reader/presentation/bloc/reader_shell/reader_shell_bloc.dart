import 'package:flutter_bloc/flutter_bloc.dart';
import 'reader_shell_event.dart';
import 'reader_shell_state.dart';

/// View-state bloc for the reader main column.
///
/// Owns the minimum state needed to drive the column UI: which text is
/// loaded, where it came from, whether the reader page is showing, and
/// any in-flight PDF progress. Heavy processing (syllabification,
/// ruler, display metrics) stays in [ReaderBloc]; this bloc is a thin
/// dispatcher the shell can talk to from anywhere in the widget tree.
class ReaderShellBloc extends Bloc<ReaderShellEvent, ReaderShellState> {
  ReaderShellBloc() : super(ReaderShellState.empty) {
    on<LoadTextEvent>(_onLoadText);
    on<ClearTextEvent>(_onClearText);
    on<SetPdfProgressEvent>(_onSetPdfProgress);
    on<ClearPdfProgressEvent>(_onClearPdfProgress);
  }

  void _onLoadText(LoadTextEvent event, Emitter<ReaderShellState> emit) {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(
        text: '',
        source: null,
        showReader: false,
      ));
      return;
    }
    final sourceChanged = state.source != event.source;
    emit(state.copyWith(
      text: event.text,
      source: event.source,
      showReader: true,
    ));
    // sourceChanged reserved for future use; suppress unused warning.
    assert(sourceChanged || !sourceChanged);
  }

  void _onClearText(ClearTextEvent event, Emitter<ReaderShellState> emit) {
    emit(state.copyWith(
      text: '',
      source: null,
      showReader: false,
    ));
  }

  void _onSetPdfProgress(
      SetPdfProgressEvent event, Emitter<ReaderShellState> emit) {
    if (event.current >= event.total) {
      emit(state.copyWith(pdfProgress: null));
    } else {
      emit(state.copyWith(
        pdfProgress: (
          current: event.current,
          total: event.total,
        ),
      ));
    }
  }

  void _onClearPdfProgress(
      ClearPdfProgressEvent event, Emitter<ReaderShellState> emit) {
    emit(state.copyWith(pdfProgress: null));
  }
}
