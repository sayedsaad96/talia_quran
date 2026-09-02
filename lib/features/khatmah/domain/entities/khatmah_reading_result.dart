import 'khatmah_history_entry.dart';
import 'khatmah_plan.dart';

enum KhatmahReadingSource { digital, physical }

class KhatmahProgressException implements Exception {
  const KhatmahProgressException(this.message);

  final String message;

  @override
  String toString() => 'KhatmahProgressException: $message';
}

class KhatmahReadingResult {
  KhatmahReadingResult({
    required this.plan,
    this.historyEntry,
    required Iterable<int> newlyCompletedPages,
  }) : newlyCompletedPages = Set.unmodifiable(newlyCompletedPages);

  final KhatmahPlan plan;
  final KhatmahHistoryEntry? historyEntry;
  final Set<int> newlyCompletedPages;

  bool get completed => historyEntry != null;
}
