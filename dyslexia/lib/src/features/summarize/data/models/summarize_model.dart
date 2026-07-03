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

class SummarizeResponseModel {
  final String result;
  final String feature;
  final String sessionId;
  final String? historyId;

  const SummarizeResponseModel({
    required this.result,
    required this.feature,
    required this.sessionId,
    this.historyId,
  });

  factory SummarizeResponseModel.fromJson(Map<String, dynamic> json) =>
      SummarizeResponseModel(
        result: json['result'] as String,
        feature: json['feature'] as String,
        sessionId: json['session_id'] as String,
        historyId: json['history_id'] as String?,
      );
}
