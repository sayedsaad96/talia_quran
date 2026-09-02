import 'dart:math';

import '../../domain/entities/khatmah_history_entry.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_reading_result.dart';
import '../../domain/repositories/khatmah_repository.dart';
import '../datasources/khatmah_local_datasource.dart';
import '../models/khatmah_history_model.dart';
import '../models/khatmah_plan_model.dart';

class KhatmahRepositoryImpl implements KhatmahRepository {
  KhatmahRepositoryImpl(this._datasource);

  final KhatmahLocalDatasource _datasource;
  Future<void> _completionQueue = Future.value();

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
    final completion = _completionQueue.then((_) => _completePlan(plan));
    _completionQueue = completion.then<void>((_) {}, onError: (_, _) {});
    return completion;
  }

  Future<KhatmahHistoryEntry> _completePlan(KhatmahPlan plan) async {
    if (!plan.isComplete) {
      throw const KhatmahProgressException(
        'Every Quran page must be explicitly recorded before completion.',
      );
    }
    final history = await _datasource.getHistory();
    for (final entry in history) {
      if (entry.id == plan.id) {
        await _datasource.deletePlan(expectedPlanId: plan.id);
        return entry.toEntity();
      }
    }

    final count = history.length;
    final completedDate = plan.lastReadDate ?? DateTime.now();
    final totalDays = max(1, completedDate.difference(plan.startDate).inDays + 1);
    final entry = KhatmahHistoryModel.fromEntity(
      KhatmahHistoryEntry(
        id: plan.id,
        khatmahNumber: count + 1,
        title: plan.title,
        startDate: plan.startDate,
        completedDate: completedDate,
        totalDays: totalDays,
        dedication: plan.dedication.isDedicated ? plan.dedication : null,
      ),
    );
    final persistedEntry = await _datasource.addHistoryEntry(entry);
    await _datasource.deletePlan(expectedPlanId: plan.id);
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
