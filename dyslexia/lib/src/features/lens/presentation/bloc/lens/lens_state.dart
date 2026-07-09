part of 'lens_bloc.dart';

abstract class LensState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LensInitialState extends LensState {}

/// Camera is initialising.
class LensStartingState extends LensState {}

/// Live scanning — carries the latest recognised frame (lines + boxes +
/// stabilised text). Emitted with [RecognizedFrame.empty] first so the
/// preview renders before the first OCR result.
class LensLiveState extends LensState {
  final RecognizedFrame frame;
  LensLiveState(this.frame);

  @override
  List<Object?> get props => [frame];
}

/// Text captured — ready to hand off to the reader.
class LensSuccessState extends LensState {
  final DocumentEntity document;
  LensSuccessState(this.document);

  @override
  List<Object?> get props => [document];
}

class LensFailureState extends LensState {
  final String message;
  LensFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
