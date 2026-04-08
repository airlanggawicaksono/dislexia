import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/entities/document_entity.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/utils/failure_converter.dart';
import '../../../domain/usecases/pick_and_extract_usecase.dart';

part 'upload_event.dart';
part 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final PickAndExtractUseCase _pickAndExtract;

  UploadBloc(this._pickAndExtract) : super(UploadInitialState()) {
    on<PickAndExtractEvent>(_onPickAndExtract);
  }

  Future<void> _onPickAndExtract(
      PickAndExtractEvent event, Emitter<UploadState> emit) async {
    emit(UploadLoadingState());
    final result = await _pickAndExtract.call(NoParams());
    result.fold(
      (l) => emit(UploadFailureState(mapFailureToMessage(l))),
      (r) => emit(UploadSuccessState(r)),
    );
  }
}
