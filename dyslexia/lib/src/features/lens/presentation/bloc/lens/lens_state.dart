part of 'lens_bloc.dart';

abstract class LensState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LensInitialState extends LensState {}

class LensLoadingState extends LensState {}

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
