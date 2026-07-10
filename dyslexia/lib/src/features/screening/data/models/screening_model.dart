class ScreeningReplyRequestModel {
  final String text;
  final String sessionId;

  const ScreeningReplyRequestModel({
    required this.text,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'session_id': sessionId,
      };
}

class ScreeningResponseModel {
  final String result;
  final String sessionId;
  final String? historyId;
  final bool isComplete;

  const ScreeningResponseModel({
    required this.result,
    required this.sessionId,
    this.historyId,
    required this.isComplete,
  });

  // Note: the API also returns internal gate keys (answered / answered_count /
  // total_topics). The frontend deliberately ignores them — it only reacts to
  // is_complete + the post-process result. Keep this boundary clean.
  factory ScreeningResponseModel.fromJson(Map<String, dynamic> json) =>
      ScreeningResponseModel(
        result: json['result'] as String,
        sessionId: json['session_id'] as String,
        historyId: json['history_id'] as String?,
        isComplete: json['is_complete'] as bool? ?? false,
      );
}
