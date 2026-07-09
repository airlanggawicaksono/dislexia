part of 'lens_bloc.dart';

abstract class LensEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Start the camera + live recognition.
class StartLensEvent extends LensEvent {}

/// Stop the camera and release resources.
class StopLensEvent extends LensEvent {}

/// Capture the current stabilised text into a document (for the reader).
class CaptureTextEvent extends LensEvent {}

/// Internal: a new recognised frame arrived on the repository stream.
class _FrameReceivedEvent extends LensEvent {
  final RecognizedFrame frame;
  _FrameReceivedEvent(this.frame);

  @override
  List<Object?> get props => [frame];
}
