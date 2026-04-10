part of 'lens_bloc.dart';

abstract class LensEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CaptureTextEvent extends LensEvent {}

class AnalyzeFrameEvent extends LensEvent {
  final AnalysisImage image;
  AnalyzeFrameEvent(this.image);

  @override
  List<Object?> get props => [image];
}
