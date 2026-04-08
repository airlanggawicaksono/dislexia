import 'package:equatable/equatable.dart';

class DocumentEntity extends Equatable {
  final String? id;
  final String? text;
  final String? sourceName;

  const DocumentEntity({
    this.id,
    this.text,
    this.sourceName,
  });

  @override
  List<Object?> get props => [id, text, sourceName];
}
