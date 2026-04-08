import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/entities/document_entity.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/utils/failure_converter.dart';
import '../../../domain/usecases/scan_text_usecase.dart';

part 'scan_event.dart';
part 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final ScanTextUseCase _scanText;

  ScanBloc(this._scanText) : super(ScanInitialState()) {
    on<StartScanEvent>(_onStartScan);
  }

  Future<void> _onStartScan(
      StartScanEvent event, Emitter<ScanState> emit) async {
    emit(ScanLoadingState());
    final result = await _scanText.call(NoParams());
    result.fold(
      (l) => emit(ScanFailureState(mapFailureToMessage(l))),
      (r) => emit(ScanSuccessState(r)),
    );
  }
}
