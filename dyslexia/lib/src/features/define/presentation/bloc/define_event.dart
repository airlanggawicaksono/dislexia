import 'package:equatable/equatable.dart';

abstract class DefineEvent extends Equatable {
  const DefineEvent();
  @override
  List<Object?> get props => [];
}

class DefineTextEvent extends DefineEvent {
  final String text;
  const DefineTextEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class ClearDefineEvent extends DefineEvent {}
