import '../entities/khatmah_history_entry.dart';
import '../entities/khatmah_plan.dart';

abstract class KhatmahRepository {
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
