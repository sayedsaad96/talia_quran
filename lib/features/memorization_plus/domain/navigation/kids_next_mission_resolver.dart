import 'package:equatable/equatable.dart';

import '../entities/memorization_entities.dart';
import '../services/kids_daily_budget.dart';
import '../services/kids_due_review_policy.dart';

/// The single actionable task shown on the kids home screen.
final class KidsNextMission extends Equatable {
  const KidsNextMission({
    required this.type,
    required this.surahId,
    required this.ayahNumbers,
  });

  final KidsMissionType type;
  final int surahId;
  final List<int> ayahNumbers;

  int get startAyah => ayahNumbers.first;

  @override
  List<Object?> get props => [type, surahId, ayahNumbers];
}

/// Loads a surah's kids journey stages; null when the journey is unreadable.
typedef KidsSurahStagesLoader =
    Future<List<KidsJourneyStage>?> Function(int surahId);

/// Where the journey continues once the active surah has no open stage,
/// found by [KidsNextMissionResolver.findContinuation]. A null [mission]
/// means every remaining Juz Amma surah is already memorized (K17).
final class KidsJourneyContinuation extends Equatable {
  const KidsJourneyContinuation(this.mission);

  final KidsNextMission? mission;

  @override
  List<Object?> get props => [mission];
}

/// Resolves one distraction-free kids mission using the product priority:
/// due review, resumed session, linked review, current memorization, then the
/// next surah on [KidsJourneyPath] (Al-Fatiha, then An-Nas down to An-Naba).
final class KidsNextMissionResolver {
  const KidsNextMissionResolver({
    this.lastJuzAmmaSurahId = KidsJourneyPath.lastSurahId,
  });

  /// Where the path ends (An-Naba by default).
  final int lastJuzAmmaSurahId;

  int? _nextSurah(int surahId) =>
      KidsJourneyPath.nextAfter(surahId, lastSurahId: lastJuzAmmaSurahId);

  KidsNextMission? resolve({
    required int activeSurahId,
    required List<KidsJourneyStage> stages,
    KidsNextMission? resumableMission,
    required List<AyahReviewRecord> reviewRecords,
    required DateTime now,
    KidsDailyBudget budget = KidsDailyBudget.unlimited,
    KidsJourneyContinuation? continuation,
  }) {
    final dueReviews =
        reviewRecords
            .where(
              (record) =>
                  record.createdByMode == ReviewRecordCreatedByMode.kidsMode &&
                  KidsDueReviewPolicy.isDue(record, now),
            )
            .toList()
          ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    // Due reviews lead the pipeline, but a daily budget keeps a persistent
    // STT false-negative loop from starving the child of new memorization
    // forever. An unlimited budget keeps the previous behavior — fail-open
    // when policy or logs are unavailable to the caller.
    if (dueReviews.isNotEmpty && !budget.dueReviewBudgetExhausted) {
      final record = dueReviews.first;
      return KidsNextMission(
        type: KidsMissionType.dueReview,
        surahId: record.surahId,
        ayahNumbers: [record.ayahNumber],
      );
    }
    if (resumableMission != null) return resumableMission;

    // A stage "needs review" because it holds a due record, so the due-review
    // branch above already covers it. Once that budget is spent, offering the
    // stage again would only replay its first ayah (never the due one) with
    // no budget of its own, trapping the child there for the rest of the
    // day (K19). The due ayah comes back tomorrow through the budget.
    if (!budget.dueReviewBudgetExhausted) {
      for (final stage in stages) {
        if (stage.status != KidsJourneyStageStatus.needsReview) continue;
        return KidsNextMission(
          type: KidsMissionType.linkedReview,
          surahId: stage.surahId,
          ayahNumbers: _completedOrRange(stage),
        );
      }
    }

    // Today's new-ayah quota is used up: never offer a mission the session
    // gate would refuse (N3). Callers show the "day complete" card instead.
    if (budget.newAyahLimitReached) return null;

    for (final stage in stages) {
      if (!_isOpen(stage)) continue;
      return KidsNextMission(
        type: KidsMissionType.newMemorization,
        surahId: stage.surahId,
        // Single source of truth: the entity's gap-aware next-ayah rule
        // (K4), so home, stage page, and completion agree by construction.
        ayahNumbers: [stage.nextAyahToStart],
      );
    }

    if (continuation != null) return continuation.mission;

    // Without a continuation the caller could not look ahead: keep starting
    // the next surah on the path from its first ayah.
    final nextSurahId = _nextSurah(activeSurahId);
    if (nextSurahId != null && stages.isNotEmpty) {
      return KidsNextMission(
        type: KidsMissionType.newMemorization,
        surahId: nextSurahId,
        ayahNumbers: const [1],
      );
    }

    return null;
  }

  /// Resolves the next mission right after the child completed one ayah, used
  /// by the completion screen. Re-runs the exact same SRS-first pipeline with
  /// that ayah presumed completed, so due reviews (K5) keep their priority and
  /// the just-completed ayah is never reopened.
  KidsNextMission? resolveSkippingAyah({
    required int activeSurahId,
    required List<KidsJourneyStage> stages,
    KidsNextMission? resumableMission,
    required List<AyahReviewRecord> reviewRecords,
    required DateTime now,
    required int justCompletedSurahId,
    required int justCompletedAyah,
    KidsDailyBudget budget = KidsDailyBudget.unlimited,
    KidsJourneyContinuation? continuation,
  }) {
    return resolve(
      activeSurahId: activeSurahId,
      stages: withCompletedAyah(
        stages,
        surahId: justCompletedSurahId,
        ayahNumber: justCompletedAyah,
      ),
      resumableMission: resumableMission,
      reviewRecords: reviewRecords,
      now: now,
      budget: budget,
      continuation: continuation,
    );
  }

  /// [stages] with [ayahNumber] of [surahId] presumed completed.
  static List<KidsJourneyStage> withCompletedAyah(
    List<KidsJourneyStage> stages, {
    required int surahId,
    required int ayahNumber,
  }) => stages
      .map(
        (stage) => stage.surahId == surahId
            ? stage.copyWithAddedCompletedAyah(ayahNumber)
            : stage,
      )
      .toList(growable: false);

  /// Looks past a fully memorized [activeSurahId] for the real journey
  /// frontier: the first later surah on the path that still has an open stage,
  /// and its first incomplete ayah (K17). Blindly starting "the next surah at
  /// ayah 1" reopens ayahs the child already memorized — they earn nothing
  /// and write no log, so the same mission would come back forever.
  ///
  /// Returns null while [stages] still has open work (no look-ahead needed).
  /// An unreadable surah journey falls back to starting that surah.
  Future<KidsJourneyContinuation?> findContinuation({
    required int activeSurahId,
    required List<KidsJourneyStage> stages,
    required KidsSurahStagesLoader loadStages,
  }) async {
    if (stages.isEmpty || stages.any(_isOpen)) return null;
    for (
      var surahId = _nextSurah(activeSurahId);
      surahId != null;
      surahId = _nextSurah(surahId)
    ) {
      final surahStages = await loadStages(surahId);
      if (surahStages == null || surahStages.isEmpty) {
        return KidsJourneyContinuation(
          KidsNextMission(
            type: KidsMissionType.newMemorization,
            surahId: surahId,
            ayahNumbers: const [1],
          ),
        );
      }
      for (final stage in surahStages) {
        if (!_isOpen(stage)) continue;
        return KidsJourneyContinuation(
          KidsNextMission(
            type: KidsMissionType.newMemorization,
            surahId: surahId,
            ayahNumbers: [stage.nextAyahToStart],
          ),
        );
      }
    }
    return const KidsJourneyContinuation(null);
  }

  /// Today's new-ayah cap when it alone holds back new memorization, so the
  /// child sees "day complete"; null otherwise. A finished journey is never
  /// reported as a capped day (K18). [resolveWith] re-runs the caller's exact
  /// resolution with another budget.
  int? dailyGoalCap({
    required KidsNextMission? mission,
    required KidsDailyBudget budget,
    required KidsNextMission? Function(KidsDailyBudget budget) resolveWith,
  }) {
    if (mission != null || !budget.newAyahLimitReached) return null;
    final uncapped = resolveWith(budget.withoutNewAyahCap);
    return uncapped == null ? null : budget.maxNewAyahsPerDay;
  }

  /// A stage with an ayah left to memorize.
  static bool _isOpen(KidsJourneyStage stage) =>
      stage.status == KidsJourneyStageStatus.current &&
      stage.completedCount < stage.totalAyahs;

  static List<int> _completedOrRange(KidsJourneyStage stage) {
    if (stage.completedAyahs.isNotEmpty) {
      final ayahs = stage.completedAyahs.toSet().toList()..sort();
      return ayahs;
    }
    return List<int>.generate(
      stage.totalAyahs,
      (index) => stage.startAyah + index,
    );
  }
}
