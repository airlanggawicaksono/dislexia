import 'package:equatable/equatable.dart';

abstract class ProfessionalizeState extends Equatable {
  const ProfessionalizeState();
  @override
  List<Object?> get props => [];
}

class ProfessionalizeInitial extends ProfessionalizeState {}

class ProfessionalizeLoading extends ProfessionalizeState {}

class ProfessionalizeResultState extends ProfessionalizeState {
  final String inputText;
  final String result;

  const ProfessionalizeResultState({required this.inputText, required this.result});

  @override
  List<Object?> get props => [inputText, result];
}

class ProfessionalizeErrorState extends ProfessionalizeState {
  final String message;
  const ProfessionalizeErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
