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
  Future<void> _mutationQueue = Future.value();

  Future<T> _enqueueMutation<T>(Future<T> Function() mutation) {
    final result = _mutationQueue.then<T>((_) => mutation());
    _mutationQueue = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  @override
  Future<KhatmahPlan?> getActivePlan() async {
    final model = await _datasource.getActivePlan();
    return model?.toEntity();
  }

  @override
  Future<void> createPlan(KhatmahPlan plan) async {
    await _enqueueMutation(
      () => _datasource.savePlan(KhatmahPlanModel.fromEntity(plan)),
    );
  }

  @override
  Future<KhatmahPlan?> createPlanIfAbsent(KhatmahPlan plan) {
    return _enqueueMutation(() async {
      final existing = (await _datasource.getActivePlan())?.toEntity();
      if (existing != null &&
          (existing.status == KhatmahStatus.active ||
              existing.status == KhatmahStatus.paused)) {
        return existing;
      }
      if (existing?.status == KhatmahStatus.completed) {
        final removed = await _datasource.deletePlan(
          expectedPlanId: existing!.id,
        );
        if (!removed) {
          final replacement = (await _datasource.getActivePlan())?.toEntity();
          if (replacement != null) return replacement;
        }
      }
      await _datasource.savePlan(KhatmahPlanModel.fromEntity(plan));
      return null;
    });
  }

  @override
  Future<void> updatePlan(KhatmahPlan plan) async {
    await _enqueueMutation(
      () => _datasource.savePlan(KhatmahPlanModel.fromEntity(plan)),
    );
  }

  @override
  Future<void> deletePlan({String? expectedPlanId}) async {
    await _enqueueMutation(() async {
      final removed = await _datasource.deletePlan(
        expectedPlanId: expectedPlanId,
      );
      if (!removed) {
        throw const KhatmahProgressException(
          'The current Khatmah changed. View it before ending a plan.',
        );
      }
    });
  }

  @override
  Future<KhatmahHistoryEntry> completePlan(KhatmahPlan plan) async {
    return _enqueueMutation(() => _completePlan(plan));
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
    final totalDays = plan.actualElapsedDays(completedDate);
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
