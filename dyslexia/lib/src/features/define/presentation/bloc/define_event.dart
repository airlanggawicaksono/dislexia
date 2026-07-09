import 'package:equatable/equatable.dart';

import '../../domain/entities/define_level.dart';

abstract class DefineEvent extends Equatable {
  const DefineEvent();
  @override
  List<Object?> get props => [];
}

class DefineTextEvent extends DefineEvent {
  final String text;
  final DefineLevel? level;
  const DefineTextEvent(this.text, {this.level});

  @override
  List<Object?> get props => [text, level];
}

class ClearDefineEvent extends DefineEvent {}
