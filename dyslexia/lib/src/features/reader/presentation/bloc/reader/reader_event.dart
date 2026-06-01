import 'package:equatable/equatable.dart';

abstract class ReaderEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SetTextEvent extends ReaderEvent {
  final String text;
  final String? sourceName;
  SetTextEvent(this.text, {this.sourceName});
  @override
  List<Object?> get props => [text, sourceName];
}

class ToggleSyllabifyEvent extends ReaderEvent {}

class UpdateRulerPositionEvent extends ReaderEvent {
  final double position;
  UpdateRulerPositionEvent(this.position);
  @override
  List<Object?> get props => [position];
}

class UpdateRulerHeightEvent extends ReaderEvent {
  final double height;
  UpdateRulerHeightEvent(this.height);
  @override
  List<Object?> get props => [height];
}
