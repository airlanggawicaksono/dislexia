class ScreeningResult {
  final String text;
  final String sessionId;
  final String? historyId;
  final bool isComplete;

  const ScreeningResult({
    required this.text,
    required this.sessionId,
    this.historyId,
    required this.isComplete,
  });
}
