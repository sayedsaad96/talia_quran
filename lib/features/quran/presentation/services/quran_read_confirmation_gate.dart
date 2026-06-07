class QuranReadConfirmationGate {
  final Set<int> _confirmedPages = {};
  final Set<int> _interactedPages = {};
  final Set<int> _timerElapsedPages = {};
  final Set<int> _pendingPages = {};

  bool hasConfirmed(int pageNumber) => _confirmedPages.contains(pageNumber);

  bool hasPending(int pageNumber) => _pendingPages.contains(pageNumber);

  bool registerInteraction(int pageNumber) {
    _interactedPages.add(pageNumber);
    return shouldConfirm(pageNumber);
  }

  bool registerTimerElapsed(int pageNumber) {
    _timerElapsedPages.add(pageNumber);
    return shouldConfirm(pageNumber);
  }

  bool shouldConfirm(int pageNumber) {
    return !_confirmedPages.contains(pageNumber) &&
        !_pendingPages.contains(pageNumber) &&
        _interactedPages.contains(pageNumber) &&
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
