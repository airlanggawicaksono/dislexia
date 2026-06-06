import 'package:equatable/equatable.dart';

abstract class DefineState extends Equatable {
  const DefineState();
  @override
  List<Object?> get props => [];
}

class DefineInitial extends DefineState {}

class DefineLoading extends DefineState {}

class DefineResultState extends DefineState {
  final String inputText;
  final String result;

  const DefineResultState({required this.inputText, required this.result});

  @override
  List<Object?> get props => [inputText, result];
}

class DefineErrorState extends DefineState {
  final String message;
  const DefineErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
