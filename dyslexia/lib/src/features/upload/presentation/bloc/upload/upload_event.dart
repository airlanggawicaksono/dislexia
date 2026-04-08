part of 'upload_bloc.dart';

abstract class UploadEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PickAndExtractEvent extends UploadEvent {}
