/// De-jitters live OCR text without getting stuck.
///
/// Strategy: show the first read at once. After that, keep showing the
/// committed text only while incoming reads still match it. The moment the
/// scene changes — incoming reads keep *differing* from what's shown for
/// [switchAfter] frames — adopt the latest read immediately. Crucially this
/// keys off "the shown text is stale", NOT "the new text matches itself",
/// so jittery small text (which rarely repeats identically) still takes
/// over quickly instead of being held back by the previous dense read.
///
/// A sustained empty view clears the panel after [emptyTolerance] frames.
/// Pure + synchronous → trivially testable.
class OcrStabilizer {
  final int switchAfter;
  final int emptyTolerance;

  OcrStabilizer({this.switchAfter = 1, this.emptyTolerance = 3});

  String _committedRaw = '';
  int _staleCount = 0;
  int _emptyStreak = 0;

  String stabilize(String raw) {
    final norm = _normalize(raw);

    if (norm.isEmpty) {
      _emptyStreak++;
      if (_emptyStreak > emptyTolerance) {
        _committedRaw = '';
        _staleCount = 0;
      }
      return _committedRaw;
    }
    _emptyStreak = 0;

    if (norm == _normalize(_committedRaw)) {
      _staleCount = 0; // still what we're showing
      return _committedRaw;
    }

    // Incoming differs from what's shown.
    _staleCount++;
    if (_committedRaw.isEmpty || _staleCount >= switchAfter) {
      _committedRaw = raw; // scene changed → take the latest
      _staleCount = 0;
    }
    return _committedRaw;
  }

  void reset() {
    _committedRaw = '';
    _staleCount = 0;
    _emptyStreak = 0;
  }

  static String _normalize(String s) =>
      s.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}
