import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../../../../core/utils/font_utils.dart';
import '../../../data/models/reader_model.dart';
import '../../../domain/entities/reader_entity.dart';
import '../../../domain/repositories/reader_repository.dart';
import 'reader_event.dart';
import 'reader_state.dart';

EventTransformer<T> debounce<T>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final ReaderRepository _repository;

  ReaderBloc(this._repository) : super(const ReaderState()) {
    on<SetTextEvent>(
      _onSetText,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
    on<ToggleSyllabifyEvent>(_onToggleSyllabify);
    on<UpdateRulerPositionEvent>(_onUpdateRulerPosition);
    on<UpdateRulerHeightEvent>(_onUpdateRulerHeight);
  }

  Future<void> _onSetText(
      SetTextEvent event, Emitter<ReaderState> emit) async {
    if (event.text.isEmpty) {
      emit(state.copyWith(reader: null, displayText: ''));
      return;
    }
    final reader = ReaderModel(
      text: event.text,
      sourceName: event.sourceName,
      syllabifyEnabled: true,
      rulerPosition: 0.0,
      rulerHeight: 48.0,
    );
    final display = await _repository.syllabify(reader.text);
    if (!isClosed) emit(state.copyWith(reader: reader, displayText: display));
  }

  Future<void> _onToggleSyllabify(
      ToggleSyllabifyEvent event, Emitter<ReaderState> emit) async {
    if (state.reader == null) return;
    final updated = ReaderModel.fromEntity(state.reader!).copyWith(
      syllabifyEnabled: !state.reader!.syllabifyEnabled,
    );
    final display = updated.syllabifyEnabled
        ? await _repository.syllabify(updated.text)
        : updated.text;
    if (!isClosed) emit(state.copyWith(reader: updated, displayText: display));
  }

  void _onUpdateRulerPosition(
      UpdateRulerPositionEvent event, Emitter<ReaderState> emit) {
    if (state.reader == null) return;
    final updated = ReaderModel.fromEntity(state.reader!)
        .copyWith(rulerPosition: event.position);
    emit(state.copyWith(reader: updated));
  }

  void _onUpdateRulerHeight(
      UpdateRulerHeightEvent event, Emitter<ReaderState> emit) {
    if (state.reader == null) return;
    final updated = ReaderModel.fromEntity(state.reader!)
        .copyWith(rulerHeight: event.height);
    emit(state.copyWith(reader: updated));
  }
}
