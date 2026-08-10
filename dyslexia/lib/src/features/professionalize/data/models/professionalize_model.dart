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
