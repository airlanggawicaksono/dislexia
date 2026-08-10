import '../../domain/entities/define_level.dart';

class DefineRequestModel {
  final String text;
  final String? sessionId;
  final DefineLevel? level;

  const DefineRequestModel({required this.text, this.sessionId, this.level});

  Map<String, dynamic> toJson() => {
        'text': text,
        if (sessionId != null) 'session_id': sessionId,
        if (level != null) 'level': level!.apiValue,
      };
}
