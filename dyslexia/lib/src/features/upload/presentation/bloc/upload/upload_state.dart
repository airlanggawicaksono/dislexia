part of 'upload_bloc.dart';

abstract class UploadState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UploadInitialState extends UploadState {}

class UploadLoadingState extends UploadState {}

class UploadSuccessState extends UploadState {
  final DocumentEntity document;
  UploadSuccessState(this.document);

  @override
  List<Object?> get props => [document];
}

class UploadFailureState extends UploadState {
  final String message;
  UploadFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
