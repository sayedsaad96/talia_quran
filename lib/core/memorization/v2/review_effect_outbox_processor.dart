import 'package:isar/isar.dart';

import '../../../features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import '../../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../../features/streak/data/models/daily_activity_isar.dart';
import '../../../features/streak/data/models/streak_isar.dart';
import '../../../features/xp/data/models/xp_isar.dart';
import '../../constants/xp_constants.dart';
import '../../identity/record_owner_provider.dart';
import '../../progress/progress_changed_reason.dart';
import '../../progress/progress_events_bus.dart';
import '../../services/achievement_service.dart';

/// Consumes durable review effects without replaying rewards after a crash.
///
/// XP, streak data and their outbox receipt share one Isar transaction. A
/// certificate is already idempotent by certificate id in its own store, then
/// receives its durable receipt after the check completes. Sync stays pending
/// until the append-only cloud event transport is introduced.
final class V2ReviewEffectOutboxProcessor {
  V2ReviewEffectOutboxProcessor({
    required Isar isar,
    required RecordOwnerProvider owner,
    required MarkDailyPlanAyahCompletedUsecase markDailyPlanCompleted,
    required AchievementService achievements,
    required ProgressEventsBus progressEvents,
    DateTime Function()? now,
  }) : _isar = isar,
       _owner = owner,
       _markDailyPlanCompleted = markDailyPlanCompleted,
       _achievements = achievements,
       _progressEvents = progressEvents,
       _now = now ?? (() => DateTime.now().toUtc());

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final MarkDailyPlanAyahCompletedUsecase _markDailyPlanCompleted;
  final AchievementService _achievements;
  final ProgressEventsBus _progressEvents;
  final DateTime Function() _now;
  Future<List<CertificateAward>>? _activeRun;

  /// Processes effects for the active account. A caller that arrives during a
  /// run waits, then drains any receipts written while that run was active.
  /// This prevents a terminal completion screen from racing an earlier pass.
  Future<List<CertificateAward>> processPending() {
    final active = _activeRun;
    if (active != null) {
      return _waitThenDrain(active);
    }
    final run = _runSnapshot();
    _activeRun = run;
    return run;
  }

  Future<List<CertificateAward>> _waitThenDrain(
    Future<List<CertificateAward>> active,
  ) async {
    final earlierAwards = await active;
    final laterAwards = await processPending();
    return [...earlierAwards, ...laterAwards];
  }

  Future<List<CertificateAward>> _runSnapshot() async {
    try {
      return await _processSnapshot();
    } finally {
      _activeRun = null;
    }
  }

  Future<List<CertificateAward>> _processSnapshot() async {
    final ownerId = _owner.currentOwnerId;
    final effects =
        await _isar.isarReviewEffectOutboxs
              .filter()
              .processedAtIsNull()
              .findAll()
          ..sort((a, b) => a.id.compareTo(b.id));
    final awards = <CertificateAward>[];
    for (final effect in effects) {
      if (effect.ownerId != ownerId) continue;
      awards.addAll(await _process(effect));
    }
    return awards;
  }

  Future<List<CertificateAward>> _process(IsarReviewEffectOutbox effect) async {
    try {
      return switch (effect.effectType) {
        'dailyPlanReconciliation' => await _processDailyPlan(effect),
        'xp' => await _processXp(effect),
        'streak' => await _processStreak(effect),
        'certificate' => await _processCertificate(effect),
        'completion' => await _markProcessed(effect.id),
        // Sync requires the server event RPC. Keep it durable and pending.
        'sync' => const <CertificateAward>[],
        _ => await _recordFailure(effect.id, 'unknown_effect'),
      };
    } catch (_) {
      await _recordFailure(effect.id, 'effect_processing_failed');
      return const [];
    }
  }

  Future<List<CertificateAward>> _processDailyPlan(
    IsarReviewEffectOutbox effect,
  ) async {
    final event = await _eventFor(effect);
    if (event == null) return _markProcessed(effect.id);
    final result = await _markDailyPlanCompleted(
      MarkDailyPlanAyahCompletedParams(
        surahId: event.surahId,
        ayahNumber: event.ayahNumber,
      ),
    );
    return result.fold(
      (_) => _recordFailure(effect.id, 'daily_plan_write_failed'),
      (_) => _markProcessed(effect.id),
    );
  }

  Future<List<CertificateAward>> _processXp(
    IsarReviewEffectOutbox effect,
  ) async {
    final applied = await _isar.writeTxn(() async {
      final current = await _isar.isarReviewEffectOutboxs.get(effect.id);
      if (current == null || current.processedAt != null) return false;
      if (current.ownerId != _owner.currentOwnerId) return false;
      final xp = await _isar.xpIsars.get(1) ?? XpIsar();
      xp.totalXp += XpConstants.rewards['v2_block_completed'] ?? 0;
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
      final day = _utcDay(current.createdAt);
      final dayKey = day.year * 10000 + day.month * 100 + day.day;
      final delta = current.activityDelta ?? 1;
      final streak = await _isar.streakIsars.get(1) ?? StreakIsar();
      final previous = streak.lastActivityDate;
      if (previous == null) {
        streak.currentStreak = 1;
        streak.longestStreak = 1;
        streak.lastActivityDate = day;
      } else {
        final previousDay = _utcDay(previous);
        if (previousDay.isBefore(day)) {
          final yesterday = day.subtract(const Duration(days: 1));
          streak.currentStreak = previousDay == yesterday
              ? streak.currentStreak + 1
              : 1;
          streak.longestStreak = streak.longestStreak > streak.currentStreak
              ? streak.longestStreak
              : streak.currentStreak;
          streak.lastActivityDate = day;
        }
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
      effect.attempts += 1;
      effect.lastErrorCode = code;
      await _isar.isarReviewEffectOutboxs.put(effect);
    });
    return const [];
  }

  static DateTime _utcDay(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}
