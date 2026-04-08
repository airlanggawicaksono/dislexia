part of 'scan_bloc.dart';

abstract class ScanState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ScanInitialState extends ScanState {}

class ScanLoadingState extends ScanState {}

class ScanSuccessState extends ScanState {
  final DocumentEntity document;
  ScanSuccessState(this.document);

  @override
  List<Object?> get props => [document];
}

class ScanFailureState extends ScanState {
  final String message;
  ScanFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
