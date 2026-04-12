part of 'lens_bloc.dart';

abstract class LensEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CaptureTextEvent extends LensEvent {}

class AnalyzeFrameEvent extends LensEvent {
  final String scannedText;
  final List<dynamic> rawElements;
  AnalyzeFrameEvent(
    this.scannedText, {
    this.rawElements = const [],
  });

  @override
  List<Object?> get props => [scannedText, rawElements.length];
}
