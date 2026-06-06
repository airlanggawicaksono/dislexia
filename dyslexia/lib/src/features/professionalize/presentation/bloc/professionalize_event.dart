import 'package:equatable/equatable.dart';

abstract class ProfessionalizeEvent extends Equatable {
  const ProfessionalizeEvent();
  @override
  List<Object?> get props => [];
}

class ProfessionalizeTextEvent extends ProfessionalizeEvent {
  final String text;
  const ProfessionalizeTextEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class ClearProfessionalizeEvent extends ProfessionalizeEvent {}
