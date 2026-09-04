import '../entities/khatmah_history_entry.dart';
import '../entities/khatmah_plan.dart';
import '../entities/khatmah_reading_result.dart';

abstract class KhatmahRepository {
  Stream<void>? get changes;
  Object? get authority;
  Future<KhatmahReadingResult> mutatePlan(
    KhatmahPlan expected,
    KhatmahPlan Function(KhatmahPlan current) change, {
    KhatmahStatus requiredStatus = KhatmahStatus.active,
  });
  Future<KhatmahPlan?> getActivePlan();
  Future<void> createPlan(KhatmahPlan plan);

  /// Atomically creates [plan] when active storage is absent or terminal.
  /// Returns the active/paused plan that prevented creation, if any.
  Future<KhatmahPlan?> createPlanIfAbsent(KhatmahPlan plan);
  Future<void> updatePlan(KhatmahPlan plan);
  Future<void> deletePlan({String? expectedPlanId});
  Future<KhatmahHistoryEntry> completePlan(KhatmahPlan plan);
  Future<List<KhatmahHistoryEntry>> getHistory();
  Future<int> getCompletedCount();
}
