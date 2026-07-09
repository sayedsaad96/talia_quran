// lib/core/memorization/v2/session_adapters.dart
//
// Adapter layer — bridges V2SessionEngine (pure domain) with the
// MemorizationPlusRepository (data layer) and V2SessionLocalDatasource.
//
// Two adapters:
//   V2SessionReviewAdapter   — persists AyahReviewRecord changes after a pass
//   V2SessionProgressAdapter — reads/writes IsarV2Session for session resume

import 'package:dartz/dartz.dart';

import '../../../core/services/achievement_service.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/services/xp_service.dart';
import '../../../core/utils/talia_logger.dart';
import '../../../features/memorization_plus/data/datasources/v2_session_local_datasource.dart';
import '../../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../../features/quran/domain/entities/quran_entities.dart';
import '../../../core/memorization/review_record_audience_scope.dart';
import 'hint_usage.dart';
import 'ayah_failure_tracker.dart';
import 'session_phase.dart';
import 'session_state.dart';

// ─── V2SessionReviewAdapter ───────────────────────────────────────────────────

/// Converts a passed V2 ayah into an [AyahReviewRecord] update via SM-2.
///
/// Called by [MemorizationSessionCubit] after [V2SessionEngine.evaluateRecitation]
/// returns a pass. Runs asynchronously — the Cubit fires-and-forgets after
/// optimistic UI update and does not block the phase transition.
final class V2SessionReviewAdapter {
  const V2SessionReviewAdapter({
    required MemorizationPlusRepository repository,
    required ScheduleNextReviewUsecase scheduler,
    MarkDailyPlanAyahCompletedUsecase? markDailyPlanCompleted,
  }) : _repository = repository,
       _scheduler = scheduler,
       _markDailyPlanCompleted = markDailyPlanCompleted;

  final MemorizationPlusRepository _repository;
  final ScheduleNextReviewUsecase _scheduler;
  final MarkDailyPlanAyahCompletedUsecase? _markDailyPlanCompleted;

  /// Records a passed ayah recitation using SM-2 scheduling.
  ///
  /// [hintLevel] influences the performance rating per Product Rules §5:
  ///   none      → excellent
  ///   firstWord → average
  ///   fullAyah  → weak
  Future<void> recordPass({
    required int surahId,
    required int ayahNumber,
    required V2HintLevel hintLevel,
    ReviewRecordCreatedByMode createdByMode =
        ReviewRecordCreatedByMode.v2Session,
  }) async {
    // Map hint level to SM-2 performance rating.
    final rating = switch (hintLevel) {
      V2HintLevel.none => PerformanceRating.excellent,
      V2HintLevel.firstWord => PerformanceRating.average,
      V2HintLevel.fullAyah => PerformanceRating.weak,
    };

    // Fetch existing record or build a fresh baseline.
    final readScope = ReviewRecordAudienceScope.scopeForWriteMode(createdByMode);
    final existingResult = await _repository.getReviewRecord(
      surahId,
      ayahNumber,
      scope: readScope,
    );

    final now = DateTime.now().toUtc();
    final existing = existingResult.fold((_) => null, (record) => record);

    final baseRecord =
        existing ??
        AyahReviewRecord(
          surahId: surahId,
          ayahNumber: ayahNumber,
          strengthLevel: 0,
          intervalDays: 0,
          lastReviewedAt: now,
          nextReviewDate: now,
          totalReviews: 0,
          lastRating: null,
          createdByMode: createdByMode,
        );

    // Apply SM-2 and preserve the production source tag.
    final scheduled = _scheduler
        .schedule(baseRecord, rating)
        .copyWith(createdByMode: createdByMode);

    await _repository.saveReviewRecord(scheduled);

    // B1: mark today's plan item when this ayah is in the cached plan.
    final markPlan = _markDailyPlanCompleted;
    if (markPlan != null) {
      await markPlan(
        MarkDailyPlanAyahCompletedParams(
          surahId: surahId,
          ayahNumber: ayahNumber,
        ),
      );
    }
  }

  /// Records weak ayah signals after a block review failure.
  ///
  /// Marks each weak ayah with [PerformanceRating.weak] so Smart Coach
  /// picks them up as priority items in subsequent sessions.
  Future<void> recordWeakAyahs(V2AyahFailureTracker tracker) async {
    for (final record in tracker.weakAyahs) {
      await recordPass(
        surahId: record.surahId,
        ayahNumber: record.ayahNumber,
        hintLevel: V2HintLevel.fullAyah,
      );
    }
  }
}

// ─── V2SessionProgressAdapter ─────────────────────────────────────────────────

/// Reads and writes [IsarV2Session] for session persistence (app-kill resume).
///
/// Called by [MemorizationSessionCubit]:
///   - On every phase transition → [save]
///   - On session start          → [loadIfExists] to detect resume
///   - On session complete        → [clear]
final class V2SessionProgressAdapter {
  const V2SessionProgressAdapter({required V2SessionLocalDatasource datasource})
    : _datasource = datasource;

  final V2SessionLocalDatasource _datasource;

  /// Saves current session state for resume capability.
  Future<void> save(V2SessionState state) async {
    final failureCounts = <int, int>{};
    for (final record in state.failureTracker.allFailures) {
      failureCounts[record.ayahNumber] = record.failureCount;
    }

    final hintLevels = <int, int>{};
    for (final usage in state.hintTracker.allUsages) {
      hintLevels[usage.ayahNumber] = usage.level.index;
    }

    final isar = IsarV2Session.create(
      surahId: state.surahId,
      blockAyahNumbers: state.blockAyahs.map((a) => a.numberInSurah).toList(),
      currentAyahIndex: state.currentAyahIndex,
      phaseIndex: state.phase.index,
      passedAyahNumbers: state.passedAyahNumbers,
      failureCounts: failureCounts,
      hintLevels: hintLevels,
      blockReviewRequired: state.blockReviewRequired,
    );

    await _datasource.saveSession(isar);
  }

  /// Loads a persisted session for the given surah, if one exists.
  ///
  /// Returns [Some] if a saved session is found, [None] otherwise.
  Future<Option<IsarV2Session>> loadIfExists(int surahId) async {
    final session = await _datasource.getSession(surahId);
    return session == null ? const None() : Some(session);
  }

  /// Rebuilds a live [V2SessionState] from a persisted [IsarV2Session].
  ///
  /// [blockAyahs] must be the full ayah list for the surah (already loaded by
  /// the caller) — only the persisted block subset is sliced out, matched by
  /// ayah number. Trackers are reconstructed via their public
  /// [V2AyahFailureTracker.recordFailure] / [V2HintTracker.record] methods so
  /// no new factories are required on those classes.
  ///
  /// Static because the restore logic has no datasource dependency — this keeps
  /// it pure and unit-testable without an Isar instance. The Cubit filters out
  /// terminal ([completed]) and pre-start ([created]) phases before calling
  /// this; restoring them would re-run gamification and double-award streak/XP.
  static V2SessionState restore(IsarV2Session saved, List<Ayah> blockAyahs) {
    final byNumber = {for (final a in blockAyahs) a.numberInSurah: a};
    final restoredBlock = <Ayah>[];
    for (final number in saved.blockAyahNumbers) {
      final ayah = byNumber[number];
      if (ayah != null) restoredBlock.add(ayah);
    }

    var failureTracker = const V2AyahFailureTracker();
    saved.failureCounts.forEach((ayahNumber, count) {
      for (var i = 0; i < count; i++) {
        failureTracker = failureTracker.recordFailure(
          surahId: saved.surahId,
          ayahNumber: ayahNumber,
        );
      }
    });

    var hintTracker = const V2HintTracker();
    saved.hintLevels.forEach((ayahNumber, levelIndex) {
      final level = V2HintLevel.values[levelIndex];
      hintTracker = hintTracker.record(
        surahId: saved.surahId,
        ayahNumber: ayahNumber,
        level: level,
      );
    });

    // Clamp the restored index in case the persisted block shrank (e.g. data
    // edited out-of-band). Defensive — should not happen in normal use.
    final clampedIndex = saved.currentAyahIndex.clamp(
      0,
      restoredBlock.isEmpty ? 0 : restoredBlock.length - 1,
    );

    // Defensive phaseIndex guard: a corrupted or future-enum persisted index
    // would otherwise throw RangeError and crash startSession(). Fall back to
    // [V2SessionPhase.learning] — the first restorable in-flight phase and a
    // known-good entry point that never bypasses the recitation or block-review
    // gates. The Cubit has already filtered out terminal/pre-start phases.
    const phaseValues = V2SessionPhase.values;
    final savedPhaseIndex = saved.phaseIndex;
    final phase = savedPhaseIndex >= 0 &&
            savedPhaseIndex < phaseValues.length
        ? phaseValues[savedPhaseIndex]
        : (() {
            TaliaLogger.w(
              'V2: persisted phaseIndex=$savedPhaseIndex is out of range '
              '(${phaseValues.length} phases); falling back to learning',
            );
            return V2SessionPhase.learning;
          })();

    return V2SessionState(
      surahId: saved.surahId,
      blockAyahs: restoredBlock,
      currentAyahIndex: clampedIndex,
      phase: phase,
      passedAyahNumbers: saved.passedAyahNumbers,
      hintTracker: hintTracker,
      failureTracker: failureTracker,
      blockReviewRequired: saved.blockReviewRequired,
    );
  }

  /// Deletes the saved session after completion or explicit abandon.
  Future<void> clear(int surahId) async {
    await _datasource.clearSession(surahId);
  }
}

// ─── V2SessionGamificationAdapter ────────────────────────────────────────────

/// Wires V2 block completion to the existing gamification services
/// (StreakService, XpService, AchievementService).
///
/// This is the Phase D gamification half of the master-prompt spec — the
/// progress/resume half lives in [V2SessionProgressAdapter] above. Keeping
/// them separate respects the single-responsibility of each adapter and
/// leaves the existing resume code untouched.
///
/// Called by [MemorizationSessionCubit] when [V2SessionEngine] reaches
/// [V2SessionPhase.completed] (Phase F).
final class V2SessionGamificationAdapter {
  const V2SessionGamificationAdapter({
    required StreakService streakService,
    required XpService xpService,
    required AchievementService achievementService,
  }) : _streak = streakService,
       _xp = xpService,
       _achievements = achievementService;

  final StreakService _streak;
  final XpService _xp;
  final AchievementService _achievements;

  /// Awards streak activity + XP, then checks for newly unlocked certificates.
  ///
  /// Returns any **newly** earned [CertificateAward]s (may be empty).
  /// All failures are non-critical: gamification must never block session
  /// completion, so errors are logged and swallowed.
  Future<List<CertificateAward>> onBlockCompleted(
    V2SessionState session,
  ) async {
    try {
      // 1. Streak — count each ayah in the block as an activity unit.
      await _streak.recordActivity(activityDelta: session.totalAyahsInBlock);

      // 2. XP — single event per completed block.
      await _xp.addXp('v2_block_completed');

      // 3. Certificates — reads AyahReviewRecord across all sources
      //    (adultMemPlus + v2Session + legacy). v2Session records are
      //    adult-compatible per ReviewRecordFilters, so they qualify.
      return await _achievements.checkAndUnlockCertificates();
    } catch (e, stack) {
      TaliaLogger.e(
        'V2: Non-critical — gamification error on block complete',
        e,
        stack,
      );
      return [];
    }
  }
}
