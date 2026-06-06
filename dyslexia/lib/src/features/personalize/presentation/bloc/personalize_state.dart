import 'package:equatable/equatable.dart';

abstract class PersonalizeState extends Equatable {
  const PersonalizeState();
  @override
  List<Object?> get props => [];
}

class PersonalizeInitial extends PersonalizeState {}

class PersonalizeLoading extends PersonalizeState {}

class PersonalizeResultState extends PersonalizeState {
  final String inputText;
  final String result;

  const PersonalizeResultState({required this.inputText, required this.result});

  @override
  List<Object?> get props => [inputText, result];
}

class PersonalizeErrorState extends PersonalizeState {
  final String message;
  const PersonalizeErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
