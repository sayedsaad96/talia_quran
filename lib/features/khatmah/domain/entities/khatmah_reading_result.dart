import 'khatmah_history_entry.dart';
import 'khatmah_plan.dart';
import '../../../../core/identity/account_data_barrier.dart';

enum KhatmahReadingSource { digital, physical }

class KhatmahProgressException implements Exception {
  const KhatmahProgressException(this.message);

  final String message;

  @override
  String toString() => 'KhatmahProgressException: $message';
}

class KhatmahStorageException implements Exception {
  const KhatmahStorageException(this.message);

  final String message;

  @override
  String toString() => 'KhatmahStorageException: $message';
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

  /// Celebration requires matching persisted history and complete coverage.
  bool get isValidCompletion {
    final authority = plan.authority;
    if (authority is AccountDataLease) {
      try {
        authority.check();
      } catch (_) {
        return false;
      }
    }
    final history = historyEntry;
    return history != null &&
        history.id == plan.id &&
        plan.status == KhatmahStatus.completed &&
        plan.isComplete &&
        history.startDate == plan.startDate &&
        !history.completedDate.isBefore(plan.startDate);
  }

  int get actualElapsedDays {
    if (!isValidCompletion) {
      throw const KhatmahProgressException(
        'A persisted completion is required.',
      );
    }
    return plan.actualElapsedDays(historyEntry!.completedDate);
  }
}
