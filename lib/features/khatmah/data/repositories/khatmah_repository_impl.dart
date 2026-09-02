import 'dart:math';

import '../../domain/entities/khatmah_history_entry.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/repositories/khatmah_repository.dart';
import '../datasources/khatmah_local_datasource.dart';
import '../models/khatmah_history_model.dart';
import '../models/khatmah_plan_model.dart';

class KhatmahRepositoryImpl implements KhatmahRepository {
  KhatmahRepositoryImpl(this._datasource);

  final KhatmahLocalDatasource _datasource;

  @override
  Future<KhatmahPlan?> getActivePlan() async {
    final model = await _datasource.getActivePlan();
    return model?.toEntity();
  }

  @override
  Future<void> createPlan(KhatmahPlan plan) async {
    await _datasource.savePlan(KhatmahPlanModel.fromEntity(plan));
  }

  @override
  Future<void> updatePlan(KhatmahPlan plan) async {
    await _datasource.savePlan(KhatmahPlanModel.fromEntity(plan));
  }

  @override
  Future<void> deletePlan() async {
    await _datasource.deletePlan();
  }

  @override
  Future<KhatmahHistoryEntry> completePlan(KhatmahPlan plan) async {
    final history = await _datasource.getHistory();
    for (final entry in history) {
      if (entry.id == plan.id) {
        await _datasource.deletePlan();
        return entry.toEntity();
      }
    }

    final count = history.length;
    final now = DateTime.now();
    final totalDays = max(1, now.difference(plan.startDate).inDays + 1);
    final entry = KhatmahHistoryModel.fromEntity(
      KhatmahHistoryEntry(
        id: plan.id,
        khatmahNumber: count + 1,
        title: plan.title,
        startDate: plan.startDate,
        completedDate: now,
        totalDays: totalDays,
        dedication: plan.dedication.isDedicated ? plan.dedication : null,
      ),
    );
    final persistedEntry = await _datasource.addHistoryEntry(entry);
    await _datasource.deletePlan();
    return persistedEntry.toEntity();
  }

  @override
  Future<List<KhatmahHistoryEntry>> getHistory() async {
    final models = await _datasource.getHistory();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> getCompletedCount() => _datasource.getKhatmahCount();
}
