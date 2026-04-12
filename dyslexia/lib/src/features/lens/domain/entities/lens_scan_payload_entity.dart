import 'package:equatable/equatable.dart';

class LensScanPayloadEntity extends Equatable {
  final String scannedText;
  final List<dynamic> rawElements;

  const LensScanPayloadEntity({
    required this.scannedText,
    this.rawElements = const [],
  });

  @override
  List<Object?> get props => [scannedText, rawElements.length];
}
