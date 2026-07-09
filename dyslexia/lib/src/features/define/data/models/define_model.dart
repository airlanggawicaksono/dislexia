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

class DefineResponseModel {
  final String result;
  final String feature;
  final String sessionId;
  final String? historyId;

  const DefineResponseModel({
    required this.result,
    required this.feature,
    required this.sessionId,
    this.historyId,
  });

  factory DefineResponseModel.fromJson(Map<String, dynamic> json) =>
      DefineResponseModel(
        result: json['result'] as String,
        feature: json['feature'] as String,
        sessionId: json['session_id'] as String,
        historyId: json['history_id'] as String?,
      );
}
