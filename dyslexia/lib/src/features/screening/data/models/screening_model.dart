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

/// One message inside a pre-screening conversation set.
class ScreeningMessageModel {
  final String role; // 'user' | 'assistant'
  final String content;

  const ScreeningMessageModel({required this.role, required this.content});

  factory ScreeningMessageModel.fromJson(Map<String, dynamic> json) =>
      ScreeningMessageModel(
        role: json['role'] as String? ?? 'assistant',
        content: json['content'] as String? ?? '',
      );
}

/// A whole pre-screening conversation (a "set"): messages + progress + outcome.
/// Mirrors GET /me/screen/sessions items.
class ScreeningSessionModel {
  final String sessionId;
  final DateTime updatedAt;
  final bool isComplete;
  final int answeredCount;
  final int totalTopics;
  final String status; // 'not_started' | 'success' | 'failed'
  final Map<String, dynamic>? result;
  final List<ScreeningMessageModel> messages;

  const ScreeningSessionModel({
    required this.sessionId,
    required this.updatedAt,
    required this.isComplete,
    required this.answeredCount,
    required this.totalTopics,
    required this.status,
    this.result,
    required this.messages,
  });

  factory ScreeningSessionModel.fromJson(Map<String, dynamic> json) =>
      ScreeningSessionModel(
        sessionId: json['session_id'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isComplete: json['is_complete'] as bool? ?? false,
        answeredCount: (json['answered_count'] as num?)?.toInt() ?? 0,
        totalTopics: (json['total_topics'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'not_started',
        result: (json['result'] as Map?)?.cast<String, dynamic>(),
        messages: ((json['messages'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) =>
                ScreeningMessageModel.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}
