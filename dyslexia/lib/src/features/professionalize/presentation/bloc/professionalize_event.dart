import 'package:equatable/equatable.dart';

abstract class ProfessionalizeEvent extends Equatable {
  const ProfessionalizeEvent();
  @override
  List<Object?> get props => [];
}

class ProfessionalizeTextEvent extends ProfessionalizeEvent {
  final String text;
  final String? recipientName;
  final String? senderName;
  const ProfessionalizeTextEvent(this.text, {this.recipientName, this.senderName});

  @override
  List<Object?> get props => [text, recipientName, senderName];
}

class ClearProfessionalizeEvent extends ProfessionalizeEvent {}
