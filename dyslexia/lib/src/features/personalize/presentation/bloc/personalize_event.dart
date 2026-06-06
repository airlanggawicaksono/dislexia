import 'package:equatable/equatable.dart';

abstract class PersonalizeEvent extends Equatable {
  const PersonalizeEvent();
  @override
  List<Object?> get props => [];
}

class PersonalizeTextEvent extends PersonalizeEvent {
  final String text;
  const PersonalizeTextEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class ClearPersonalizeEvent extends PersonalizeEvent {}
