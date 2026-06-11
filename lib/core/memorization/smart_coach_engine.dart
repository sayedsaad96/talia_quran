import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import 'memorization_snapshot.dart';
import 'review_record_filters.dart';
import 'smart_coach_recommendation.dart';

/// Pure recommendation logic over a [MemorizationSnapshot].
///
/// Scans all SRS records for due items (not limited to the first surah in
/// [MemorizationSnapshot.cachedDailyPlan] generation).
class SmartCoachEngine {
  const SmartCoachEngine();

  SmartCoachRecommendation? recommend(MemorizationSnapshot snapshot) {
    if (snapshot.profile.isChild) {
      return _kidsRecommendation(snapshot);
    }
    if (snapshot.profile.isAdult) {
      return _adultMemPlusRecommendation(snapshot) ??
          _hifzDueRecommendation(snapshot);
    }
    return null;
  }

  SmartCoachRecommendation? _adultMemPlusRecommendation(
    MemorizationSnapshot snapshot,
  ) {
    final records = snapshot.reviewRecords;

    // ── Priority 1: Weak due ───────────────────────────────────────────────
    // Tie-breakers (in order):
    //   1. lowest strengthLevel  (weakest knowledge first)
    //   2. oldest nextReviewDate (most overdue first)
    //   3. highest totalReviews  (most practiced = most worth protecting)
    final weakDue = records.where((r) {
      final classification = r.reviewClassification;
      return classification.isDue &&
          r.lastRating == PerformanceRating.weak &&
          !classification.isMemorized;
    }).toList()..sort(_compareWeakDue);
    if (weakDue.isNotEmpty) {
      return _ayahRecommendation(
        kind: SmartCoachRecommendationKind.reviewWeakAyah,
        explanationCode: SmartCoachExplanationCode.weakAyahDue,
        record: weakDue.first,
        routeBuilder: _quizRouteWithAyah,
      );
    }

    // ── Priority 2: Near due ───────────────────────────────────────────────
    // Tie-breakers (in order):
    //   1. oldest nextReviewDate  (most overdue first)
    //   2. lowest strengthLevel   (weakest knowledge first)
    //   3. highest totalReviews   (most practiced = most worth protecting)
    final dueNear = records.where((r) {
      final classification = r.reviewClassification;
      return classification.isDue && classification.isNearRevision;
    }).toList()..sort(_compareNearFarDue);
    if (dueNear.isNotEmpty) {
      return _ayahRecommendation(
        kind: SmartCoachRecommendationKind.reviewDueNear,
        explanationCode: SmartCoachExplanationCode.nearRevisionDue,
        record: dueNear.first,
      );
    }

    // ── Priority 3: Far due ────────────────────────────────────────────────
    // Same tie-breaker policy as near due.
    final dueFar = records.where((r) {
      final classification = r.reviewClassification;
      return classification.isDue && classification.isFarRevision;
    }).toList()..sort(_compareNearFarDue);
    if (dueFar.isNotEmpty) {
      return _ayahRecommendation(
        kind: SmartCoachRecommendationKind.reviewDueFar,
        explanationCode: SmartCoachExplanationCode.farRevisionDue,
        record: dueFar.first,
      );
    }

    // ── Priority 4: Memorized-due retention review ─────────────────────────
    // Tie-breakers (in order):
    //   1. oldest nextReviewDate  (most overdue first)
    //   2. lowest strengthLevel   (least solidly memorized first)
    //   3. highest intervalDays   (longer intervals = more at risk of decay)
    //   4. highest totalReviews   (most practiced = most worth protecting)
    //
    // Sprint 8B: kidsMode and hifz records are excluded via
    // ReviewRecordFilters.isAdultCompatible. Priorities 1–3 are already
    // naturally safe because kidsMode records are isMemorized, and weak/
    // near/far require !isMemorized.
    final memorizedDue = records.where((r) {
      return r.reviewClassification.isMemorizedDue &&
          ReviewRecordFilters.isAdultCompatible(r);
    }).toList()..sort(ReviewRecordFilters.compareMemorizedDue);
    if (memorizedDue.isNotEmpty) {
      final record = memorizedDue.first;
      final plan = snapshot.cachedDailyPlan;
      final retentionInDailyPlan =
          plan != null &&
          plan.surahId == record.surahId &&
          plan.retentionReview.any((a) => a.ayahNumber == record.ayahNumber);
      return _ayahRecommendation(
        kind: SmartCoachRecommendationKind.memorizedReviewDue,
        explanationCode: SmartCoachExplanationCode.memorizedRetentionDue,
        record: record,
        routeBuilder: retentionInDailyPlan
            ? (surahId, _) => _dailyPlanRoute(surahId)
            : _quizRouteWithAyah,
      );
    }

    // ── Priority 5 & 6: Daily Plan ─────────────────────────────────────────
    final plan = snapshot.cachedDailyPlan;
    if (plan != null && plan.totalItems > 0) {
      final pendingNew = plan.newAyahs
          .where((a) => !plan.isCompleted(a.ayahNumber))
          .toList();
      final pendingNear = plan.nearRevision
          .where((a) => !plan.isCompleted(a.ayahNumber))
          .toList();
      final pendingFar = plan.farRevision
          .where((a) => !plan.isCompleted(a.ayahNumber))
          .toList();
      final pendingCount =
          pendingNew.length + pendingNear.length + pendingFar.length;

      // Priority 5: Continue incomplete daily plan
      // P0 hotfix: use requiredCompletedCount so retention-only completions
      // do not falsely trigger the "continue" card.
      if (plan.requiredCompletedCount > 0 && pendingCount > 0) {
        return SmartCoachRecommendation(
          kind: SmartCoachRecommendationKind.continueDailyPlan,
          explanationCode: SmartCoachExplanationCode.continueDailyPlan,
          route: _dailyPlanRoute(plan.surahId),
          surahId: plan.surahId,
          completedCount: plan.requiredCompletedCount,
          totalCount: plan.requiredCompletedCount + pendingCount,
        );
      }

      // Priority 6: New ayahs in daily plan
      if (pendingNew.isNotEmpty) {
        return SmartCoachRecommendation(
          kind: SmartCoachRecommendationKind.memorizeNewAyahs,
          explanationCode: SmartCoachExplanationCode.newAyahsAvailable,
          route: _dailyPlanRoute(plan.surahId),
          surahId: plan.surahId,
          startAyah: pendingNew.first.ayahNumber,
          endAyah: pendingNew.last.ayahNumber,
        );
      }
    }

    return null;
  }

  // ── Priority 7: Hifz due fallback ─────────────────────────────────────────
  SmartCoachRecommendation? _hifzDueRecommendation(
    MemorizationSnapshot snapshot,
  ) {
    if (snapshot.hifzDueReviews.isEmpty) return null;
    final due = snapshot.hifzDueReviews.first;
    return SmartCoachRecommendation(
      kind: SmartCoachRecommendationKind.hifzReviewDue,
      explanationCode: SmartCoachExplanationCode.hifzReviewDue,
      route: '/hifz',
      surahId: due.surahId,
      startAyah: due.ayahNumber,
    );
  }

  // ── Priority 8: Kids current mission ──────────────────────────────────────
  SmartCoachRecommendation? _kidsRecommendation(MemorizationSnapshot snapshot) {
    int? surahId;
    if (snapshot.kidsSessionLogs.isNotEmpty) {
      final logs = [
        ...snapshot.kidsSessionLogs,
      ]..sort((a, b) => b.completedAt.toUtc().compareTo(a.completedAt.toUtc()));
      surahId = logs.first.surahId;
    } else if (snapshot.customPlan != null &&
        snapshot.customPlan!.targetUser == PlanTargetUser.child &&
        snapshot.customPlan!.isActive) {
      surahId = snapshot.customPlan!.startSurahId;
    }

    final route = surahId != null && _isValidSurahId(surahId)
        ? '/memorization-plus/kids-home?surahId=$surahId'
        : '/memorization-plus/kids-home';

    return SmartCoachRecommendation(
      kind: SmartCoachRecommendationKind.kidsCurrentMission,
      explanationCode: SmartCoachExplanationCode.kidsMissionAvailable,
      route: route,
      surahId: surahId,
    );
  }

  /// Builds a [SmartCoachRecommendation] from a single [AyahReviewRecord].
  ///
  /// [routeBuilder] defaults to [_dailyPlanRoute] for near/far due items.
  /// Pass [_quizRouteWithAyah] for weak-due and memorized-due items so the
  /// exact ayah number is embedded in the route URL.
  SmartCoachRecommendation _ayahRecommendation({
    required SmartCoachRecommendationKind kind,
    required SmartCoachExplanationCode explanationCode,
    required AyahReviewRecord record,
    String Function(int surahId, int ayahNumber)? routeBuilder,
  }) {
    final route = routeBuilder != null
        ? routeBuilder(record.surahId, record.ayahNumber)
        : _dailyPlanRoute(record.surahId);
    return SmartCoachRecommendation(
      kind: kind,
      explanationCode: explanationCode,
      route: route,
      surahId: record.surahId,
      startAyah: record.ayahNumber,
      endAyah: record.ayahNumber,
    );
  }

  // ── Route builders ─────────────────────────────────────────────────────────

  static String _dailyPlanRoute(int surahId) =>
      '/memorization-plus/daily-plan?surahId=$surahId';

  /// Produces a quiz route with the exact ayah number embedded so the router's
  /// existing [_parseAyahNumbers] query-parameter handler can filter the quiz
  /// to only that ayah.
  ///
  /// Format: `/memorization-plus/quiz?surahId={id}&ayahNumbers={ayahNumber}`
  static String _quizRouteWithAyah(int surahId, int ayahNumber) =>
      '/memorization-plus/quiz?surahId=$surahId&ayahNumbers=$ayahNumber';

  // ── Comparators ────────────────────────────────────────────────────────────

  /// Weak-due tie-breaker:
  ///   1. lowest strengthLevel   (weakest knowledge first)
  ///   2. oldest nextReviewDate  (most overdue first)
  ///   3. highest totalReviews   (most practiced first)
  static int _compareWeakDue(AyahReviewRecord a, AyahReviewRecord b) {
    final strengthCmp = a.strengthLevel.compareTo(b.strengthLevel);
    if (strengthCmp != 0) return strengthCmp;
    final dateCmp = a.nextReviewDate.compareTo(b.nextReviewDate);
    if (dateCmp != 0) return dateCmp;
    return b.totalReviews.compareTo(a.totalReviews); // higher = first
  }

  /// Near/far-due tie-breaker:
  ///   1. oldest nextReviewDate  (most overdue first)
  ///   2. lowest strengthLevel   (weakest knowledge first)
  ///   3. highest totalReviews   (most practiced first)
  static int _compareNearFarDue(AyahReviewRecord a, AyahReviewRecord b) {
    final dateCmp = a.nextReviewDate.compareTo(b.nextReviewDate);
    if (dateCmp != 0) return dateCmp;
    final strengthCmp = a.strengthLevel.compareTo(b.strengthLevel);
    if (strengthCmp != 0) return strengthCmp;
    return b.totalReviews.compareTo(a.totalReviews); // higher = first
  }

  static bool _isValidSurahId(int surahId) => surahId >= 1 && surahId <= 114;
}
