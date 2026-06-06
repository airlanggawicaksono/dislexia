class DefineRequestModel {
  final String text;
  final String? sessionId;

  const DefineRequestModel({required this.text, this.sessionId});

  Map<String, dynamic> toJson() => {
        'text': text,
        if (sessionId != null) 'session_id': sessionId,
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
