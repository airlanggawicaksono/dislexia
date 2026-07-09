class ProfessionalizeRequestModel {
  final String text;
  final String? sessionId;
  final String? recipientName;
  final String? senderName;

  const ProfessionalizeRequestModel({
    required this.text,
    this.sessionId,
    this.recipientName,
    this.senderName,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        if (sessionId != null) 'session_id': sessionId,
        // Email mode: backend requires BOTH or NEITHER (422 otherwise).
        if (recipientName != null) 'recipient_name': recipientName,
        if (senderName != null) 'sender_name': senderName,
      };
}

class ProfessionalizeResponseModel {
  final String result;
  final String feature;
  final String sessionId;
  final String? historyId;

  const ProfessionalizeResponseModel({
    required this.result,
    required this.feature,
    required this.sessionId,
    this.historyId,
  });

  factory ProfessionalizeResponseModel.fromJson(Map<String, dynamic> json) =>
      ProfessionalizeResponseModel(
        result: json['result'] as String,
        feature: json['feature'] as String,
        sessionId: json['session_id'] as String,
        historyId: json['history_id'] as String?,
      );
}
