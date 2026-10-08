/// Decides when a page opened in the reader counts as read.
///
/// A page counts once its minimum reading time has elapsed while it stayed on
/// screen. No touch is required: the reader opened the page themselves, and
/// requiring one left pages read without touching the screen uncounted.
class QuranReadConfirmationGate {
  final Set<int> _confirmedPages = {};
  final Set<int> _timerElapsedPages = {};
  final Set<int> _pendingPages = {};

  /// Minimum time on a page before it counts as read: about 40 characters
  /// a second, between 5 and 25 seconds.
  static int requiredSeconds(int totalChars) =>
      (totalChars / 40).ceil().clamp(5, 25);

  bool hasConfirmed(int pageNumber) => _confirmedPages.contains(pageNumber);

  bool hasPending(int pageNumber) => _pendingPages.contains(pageNumber);

  bool registerTimerElapsed(int pageNumber) {
    _timerElapsedPages.add(pageNumber);
    return shouldConfirm(pageNumber);
  }

  bool shouldConfirm(int pageNumber) {
    return !_confirmedPages.contains(pageNumber) &&
        !_pendingPages.contains(pageNumber) &&
        _timerElapsedPages.contains(pageNumber);
  }

  void markPending(int pageNumber) {
    _pendingPages.add(pageNumber);
  }

  bool markConfirmed(int pageNumber) {
    _pendingPages.remove(pageNumber);
    return _confirmedPages.add(pageNumber);
  }

  void clearPending(int pageNumber) {
    _pendingPages.remove(pageNumber);
  }
}
