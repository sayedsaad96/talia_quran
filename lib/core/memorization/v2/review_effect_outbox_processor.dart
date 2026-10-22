import 'package:isar_community/isar.dart';

import '../../../features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import '../../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../../features/streak/data/models/daily_activity_isar.dart';
import '../../../features/streak/data/models/streak_isar.dart';
import '../../../features/xp/data/models/xp_isar.dart';
import '../../constants/xp_constants.dart';
import '../../identity/record_owner_provider.dart';
import '../../identity/account_data_barrier.dart';
import '../../progress/progress_changed_reason.dart';
import '../../progress/progress_events_bus.dart';
import '../../services/achievement_service.dart';
import '../../services/streak_day.dart';

/// Consumes durable review effects without replaying rewards after a crash.
///
/// XP, streak data and their outbox receipt share one Isar transaction. A
/// certificate is already idempotent by certificate id in its own store, then
/// receives its durable receipt after the check completes. Sync receipts stay
/// pending until the cloud evidence collaborator receives server acceptance.
final class V2ReviewEffectOutboxProcessor {
  V2ReviewEffectOutboxProcessor({
    required this._isar,
    required this._owner,
    required this._barrier,
    required this._markDailyPlanCompleted,
    required this._achievements,
    required this._progressEvents,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;
  final MarkDailyPlanAyahCompletedUsecase _markDailyPlanCompleted;
  final AchievementService _achievements;
  final ProgressEventsBus _progressEvents;
  final DateTime Function() _now;
  Future<List<CertificateAward>>? _activeRun;
  String? _activeOwnerId;

  /// Processes effects for the active account. A caller that arrives during a
  /// run waits, then drains any receipts written while that run was active.
  /// This prevents a terminal completion screen from racing an earlier pass.
  Future<List<CertificateAward>> processPending() {
    final ownerId = _owner.currentOwnerId;
    final AccountDataLease authority;
    try {
      authority = _barrier.capture()..checkOwner(ownerId);
    } on AccountDataUnavailableException {
      // Intentional: while the account barrier is blocked (switch/reset),
      // effects stay pending in the outbox and drain on the next call.
      return Future.value(const []);
    }
    final active = _activeRun;
    if (active != null) {
      return _waitThenDrain(
        active,
        authority,
        ownerId,
        includeEarlierAwards: _activeOwnerId == ownerId,
      );
    }
    _activeOwnerId = ownerId;
    final run = _runSnapshot(authority, ownerId);
    _activeRun = run;
    return run;
  }

  Future<List<CertificateAward>> _waitThenDrain(
    Future<List<CertificateAward>> active,
    AccountDataLease authority,
    String ownerId, {
    required bool includeEarlierAwards,
  }) async {
    try {
      final earlierAwards = await active;
      authority.checkOwner(ownerId);
      final laterAwards = await processPending();
      authority.checkOwner(ownerId);
      return [if (includeEarlierAwards) ...earlierAwards, ...laterAwards];
    } on AccountDataUnavailableException {
      return const [];
    }
  }

  Future<List<CertificateAward>> _runSnapshot(
    AccountDataLease authority,
    String ownerId,
  ) async {
    try {
      return await _processSnapshot(authority, ownerId);
    } on AccountDataUnavailableException {
      return const [];
    } finally {
      _activeRun = null;
      _activeOwnerId = null;
    }
  }

  Future<List<CertificateAward>> _processSnapshot(
    AccountDataLease authority,
    String ownerId,
  ) async {
    // `sync` rows stay pending until the evidence upload acknowledges them
    // (a guest keeps them for a later sign-in); this processor never handles
    // them, so it must not load that ever-growing set on every drain (A8).
    final effects =
        await _isar.isarReviewEffectOutboxs
              .filter()
              .processedAtIsNull()
              .ownerIdEqualTo(ownerId)
              .not()
              .effectTypeEqualTo('sync')
              .findAll()
          ..sort((a, b) => a.id.compareTo(b.id));
    final awards = <CertificateAward>[];
    for (final effect in effects) {
      authority.checkOwner(ownerId);
      if (effect.ownerId != ownerId) continue;
      awards.addAll(await _process(effect, authority));
    }
    authority.checkOwner(ownerId);
    return awards;
  }

  Future<List<CertificateAward>> _process(
    IsarReviewEffectOutbox effect,
    AccountDataLease authority,
  ) async {
    try {
      return switch (effect.effectType) {
        'dailyPlanReconciliation' => await _processDailyPlan(effect, authority),
        'xp' => await _processXp(effect, 'v2_block_completed'),
        'xpReview' => await _processXp(effect, 'v2_review_completed'),
        'streak' => await _processStreak(effect),
        'certificate' => await _processCertificate(effect),
        'completion' => await _markProcessed(effect.id),
        // Sync requires the server event RPC. Keep it durable and pending.
        'sync' => const <CertificateAward>[],
        _ => await _recordFailure(effect.id, 'unknown_effect'),
      };
    } on AccountDataUnavailableException {
      rethrow;
    } catch (_) {
      authority.checkOwner(effect.ownerId);
      await _recordFailure(effect.id, 'effect_processing_failed');
      return const [];
    }
  }

  Future<List<CertificateAward>> _processDailyPlan(
    IsarReviewEffectOutbox effect,
    AccountDataLease authority,
  ) => _barrier.run((lease) async {
    lease.checkOwner(effect.ownerId);
    final current = await _isar.isarReviewEffectOutboxs.get(effect.id);
    lease.checkOwner(effect.ownerId);
    if (current == null ||
        current.processedAt != null ||
        current.ownerId != effect.ownerId ||
        current.eventId != effect.eventId ||
        current.effectType != effect.effectType) {
      return const <CertificateAward>[];
    }
    final event = await _eventFor(current);
    lease.checkOwner(effect.ownerId);
    if (event == null) return _markProcessed(current.id);
    final result = await _markDailyPlanCompleted(
      MarkDailyPlanAyahCompletedParams(
        surahId: event.surahId,
        ayahNumber: event.ayahNumber,
      ),
    );
    lease.checkOwner(effect.ownerId);
    return result.fold(
      (_) => _recordFailure(effect.id, 'daily_plan_write_failed'),
      (_) => _markProcessed(effect.id),
    );
  }, authority: authority);

  Future<List<CertificateAward>> _processXp(
    IsarReviewEffectOutbox effect,
    String rewardKey,
  ) async {
    final applied = await _isar.writeTxn(() async {
      final current = await _isar.isarReviewEffectOutboxs.get(effect.id);
      if (current == null || current.processedAt != null) return false;
      if (current.ownerId != _owner.currentOwnerId) return false;
      final xp = await _isar.xpIsars.get(1) ?? XpIsar();
      xp.totalXp += XpConstants.rewards[rewardKey] ?? 0;
      xp.cloudDirty = true;
      await _isar.xpIsars.put(xp);
      current.processedAt = _now().toUtc();
      current.lastErrorCode = null;
      await _isar.isarReviewEffectOutboxs.put(current);
      return true;
    });
    if (applied) _progressEvents.notify(ProgressChangedReason.xp);
    return const [];
  }

  Future<List<CertificateAward>> _processStreak(
    IsarReviewEffectOutbox effect,
  ) async {
    final applied = await _isar.writeTxn(() async {
      final current = await _isar.isarReviewEffectOutboxs.get(effect.id);
      if (current == null || current.processedAt != null) return false;
      if (current.ownerId != _owner.currentOwnerId) return false;
      // Same rule as StreakService (local calendar day + mercy day), so
      // memorization and reading can never disagree about the streak.
      final day = StreakDay.of(current.createdAt);
      final dayKey = StreakDay.dayKey(day);
      final delta = current.activityDelta ?? 1;
      final streak = await _isar.streakIsars.get(1) ?? StreakIsar();
      final next = StreakDay.transition(
        currentStreak: streak.currentStreak,
        longestStreak: streak.longestStreak,
        lastDay: streak.lastActivityDate,
        lastMercyDay: streak.lastMercyDate,
        today: day,
      );
      if (next.isNewDay) {
        streak.currentStreak = next.currentStreak;
        streak.longestStreak = next.longestStreak;
        streak.lastMercyDate = next.lastMercyDay;
        streak.lastActivityDate = day;
      }
      streak.cloudDirty = true;
      await _isar.streakIsars.put(streak);
      final activity = await _isar.dailyActivityIsars
          .where()
          .dayKeyEqualTo(dayKey)
          .findFirst();
      if (activity == null) {
        await _isar.dailyActivityIsars.put(
          DailyActivityIsar()
            ..dayKey = dayKey
            ..activityCount = delta
            ..cloudDirty = true,
        );
      } else {
        activity.activityCount += delta;
        activity.cloudDirty = true;
        await _isar.dailyActivityIsars.put(activity);
      }
      current.processedAt = _now().toUtc();
      current.lastErrorCode = null;
      await _isar.isarReviewEffectOutboxs.put(current);
      return true;
    });
    if (applied) _progressEvents.notify(ProgressChangedReason.streak);
    return const [];
  }

  Future<List<CertificateAward>> _processCertificate(
    IsarReviewEffectOutbox effect,
  ) async {
    final event = await _eventFor(effect);
    if (event == null ||
        event.assessmentIndex != ReviewEvidenceAssessment.automatic.index) {
      return _markProcessed(effect.id);
    }
    final awards = await _achievements.checkAndUnlockCertificatesStrict(
      isKids: false,
    );
    await _markProcessed(effect.id);
    return awards;
  }

  Future<IsarReviewEvidenceEvent?> _eventFor(
    IsarReviewEffectOutbox effect,
  ) async {
    final event = await _isar.isarReviewEvidenceEvents
        .filter()
        .eventIdEqualTo(effect.eventId)
        .findFirst();
    if (event?.ownerId != _owner.currentOwnerId) return null;
    return event;
  }

  Future<List<CertificateAward>> _markProcessed(int effectId) async {
    await _isar.writeTxn(() async {
      final effect = await _isar.isarReviewEffectOutboxs.get(effectId);
      if (effect == null || effect.processedAt != null) return;
      if (effect.ownerId != _owner.currentOwnerId) return;
      effect.processedAt = _now().toUtc();
      effect.lastErrorCode = null;
      await _isar.isarReviewEffectOutboxs.put(effect);
    });
    return const [];
  }

  Future<List<CertificateAward>> _recordFailure(
    int effectId,
    String code,
  ) async {
    await _isar.writeTxn(() async {
      final effect = await _isar.isarReviewEffectOutboxs.get(effectId);
      if (effect == null || effect.processedAt != null) return;
      if (effect.ownerId != _owner.currentOwnerId) return;
      effect.attempts += 1;
      effect.lastErrorCode = code;
      await _isar.isarReviewEffectOutboxs.put(effect);
    });
    return const [];
  }
}
