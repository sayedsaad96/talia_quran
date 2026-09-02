import '../entities/khatmah_history_entry.dart';
import '../entities/khatmah_plan.dart';

abstract class KhatmahRepository {
  Future<KhatmahPlan?> getActivePlan();
  Future<void> createPlan(KhatmahPlan plan);
  Future<void> updatePlan(KhatmahPlan plan);
  Future<void> deletePlan();
  Future<void> completePlan(KhatmahPlan plan);
  Future<List<KhatmahHistoryEntry>> getHistory();
  Future<int> getCompletedCount();
}
