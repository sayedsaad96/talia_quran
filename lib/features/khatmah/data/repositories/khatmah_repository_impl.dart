import '../../../../core/identity/account_data_barrier.dart';
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
  AccountDataBarrier get _barrier => _datasource.barrier;
  @override
  Stream<void> get changes => _barrier.changes;
  @override
  Object get authority => _barrier.snapshot;

  Future<T> _run<T>(
    Future<T> Function(AccountDataLease) work, {
    Object? authority,
  }) async {
    try {
      return await _barrier.run(work, authority: authority);
    } on AccountDataUnavailableException {
      throw const KhatmahProgressException(
        'Account data changed. Reload before continuing.',
      );
    }
  }

  Future<KhatmahPlan?> _read(AccountDataLease lease) async {
    final plan = (await _datasource.getActivePlan())?.toEntity();
    lease.check();
    return plan?.copyWith(authority: lease);
  }

  @override
  Future<KhatmahPlan?> getActivePlan() => _run(_read);

  @override
  Future<void> createPlan(KhatmahPlan plan) async {
    final conflict = await createPlanIfAbsent(plan);
    if (conflict != null) {
      throw const KhatmahProgressException('An active Khatmah already exists.');
    }
  }

  @override
  Future<KhatmahPlan?> createPlanIfAbsent(KhatmahPlan plan) =>
      _run((lease) async {
        final existing = await _read(lease);
        if (existing != null) {
          final archived =
              existing.isComplete &&
              (await _datasource.getHistory()).any(
                (entry) => entry.id == existing.id,
              );
          lease.check();
          if (existing.status != KhatmahStatus.completed && !archived) {
            return existing;
          }
          await _datasource.deletePlan(expectedPlanId: existing.id);
          lease.check();
          final replacement = await _read(lease);
          if (replacement != null) return replacement;
        }
        await _barrier.stampOwner(lease);
        await _datasource.savePlan(KhatmahPlanModel.fromEntity(plan));
        lease.check();
        _barrier.notifyChanged();
        return null;
      }, authority: plan.authority);

  @override
  Future<KhatmahReadingResult> mutatePlan(
    KhatmahPlan expected,
    KhatmahPlan Function(KhatmahPlan) change, {
    KhatmahStatus requiredStatus = KhatmahStatus.active,
  }) => _run((lease) async {
    final current = await _read(lease);
    if (current == null ||
        current.id != expected.id ||
        current.status != requiredStatus) {
      throw const KhatmahProgressException(
        'The current Khatmah or its status changed. Reload before continuing.',
      );
    }
    final updated = change(current).copyWith(authority: lease);
    await _barrier.stampOwner(lease);
    if (updated.id != current.id ||
        !updated.completedPages.containsAll(current.completedPages)) {
      throw const KhatmahProgressException(
        'Khatmah mutations cannot replace a plan or remove coverage.',
      );
    }
    KhatmahHistoryEntry? entry;
    if (updated.isComplete) {
      entry = await _complete(updated, lease);
    } else {
      await _datasource.savePlan(KhatmahPlanModel.fromEntity(updated));
    }
    lease.check();
    _barrier.notifyChanged();
    return KhatmahReadingResult(
      plan: updated,
      historyEntry: entry,
      newlyCompletedPages: updated.completedPages.difference(
        current.completedPages,
      ),
    );
  }, authority: expected.authority);

  /// Legacy adapter: no arbitrary creation/replacement or stale snapshot loss.
  @override
  Future<void> updatePlan(KhatmahPlan plan) async {
    await mutatePlan(
      plan,
      (current) => plan.copyWith(
        completedPages: {...current.completedPages, ...plan.completedPages},
      ),
    );
  }

  @override
  Future<void> deletePlan({String? expectedPlanId}) => _run((lease) async {
    final current = await _read(lease);
    if (expectedPlanId != null && current?.id != expectedPlanId) {
      throw const KhatmahProgressException(
        'The current Khatmah changed. View it before ending a plan.',
      );
    }
    await _datasource.deletePlan(expectedPlanId: current?.id);
    lease.check();
    _barrier.notifyChanged();
  });

  @override
  Future<KhatmahHistoryEntry> completePlan(KhatmahPlan plan) =>
      _run((lease) async {
        final current = await _read(lease);
        final history = await _datasource.getHistory();
        lease.check();
        final exists = history.any((entry) => entry.id == plan.id);
        if (!exists &&
            current != null &&
            (current.id != plan.id || !current.isComplete)) {
          throw const KhatmahProgressException(
            'Only the current fully recorded Khatmah may complete.',
          );
        }
        if (current == null && !exists) {
          throw const KhatmahProgressException(
            'No persisted Khatmah authorizes this completion.',
          );
        }
        final entry = await _complete(
          current?.id == plan.id ? current! : plan,
          lease,
        );
        lease.check();
        _barrier.notifyChanged();
        return entry;
      }, authority: plan.authority);

  Future<KhatmahHistoryEntry> _complete(
    KhatmahPlan plan,
    AccountDataLease lease,
  ) async {
    if (!plan.isComplete) {
      throw const KhatmahProgressException(
        'Every Quran page must be explicitly recorded before completion.',
      );
    }
    final history = await _datasource.getHistory();
    lease.check();
    KhatmahHistoryModel? persisted;
    for (final entry in history) {
      if (entry.id == plan.id) persisted = entry;
    }
    if (persisted == null) {
      final completedDate = plan.lastReadDate ?? DateTime.now();
      persisted = await _datasource.addHistoryEntry(
        KhatmahHistoryModel.fromEntity(
          KhatmahHistoryEntry(
            id: plan.id,
            khatmahNumber: history.length + 1,
            title: plan.title,
            startDate: plan.startDate,
            completedDate: completedDate,
            totalDays: plan.actualElapsedDays(completedDate),
            dedication: plan.dedication.isDedicated ? plan.dedication : null,
            certificateId: 'khatmah-${plan.id}',
          ),
        ),
      );
      lease.check();
    } else if (persisted.certificateId == null) {
      persisted = await _datasource.linkCertificate(persisted.id);
      lease.check();
    }
    final active = await _read(lease);
    if (active?.id == plan.id) {
      await _datasource.deletePlan(expectedPlanId: plan.id);
      lease.check();
    }
    return persisted.toEntity();
  }

  @override
  Future<List<KhatmahHistoryEntry>> getHistory() => _run((lease) async {
    final history = await _datasource.getHistory();
    lease.check();
    return history.map((m) => m.toEntity()).toList();
  });
  @override
  Future<int> getCompletedCount() async => (await getHistory()).length;
}
