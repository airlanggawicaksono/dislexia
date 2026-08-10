import '../../domain/entities/summary_level.dart';

class SummarizeRequestModel {
  final String text;
  final String? sessionId;
  final SummaryLevel? level;

  const SummarizeRequestModel({required this.text, this.sessionId, this.level});

  Map<String, dynamic> toJson() => {
        'text': text,
        if (sessionId != null) 'session_id': sessionId,
        if (level != null) 'level': level!.apiValue,
      };
}
