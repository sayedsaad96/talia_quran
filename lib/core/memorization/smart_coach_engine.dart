import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import 'learning_launch_context.dart';
import 'memorization_snapshot.dart';
import 'pending_ayah_resolver.dart';
import 'review_record_filters.dart';
import 'smart_coach_recommendation.dart';

/// Pure recommendation logic over a [MemorizationSnapshot].
///
/// Scans all SRS records for due items (not limited to the first surah in
/// [MemorizationSnapshot.cachedDailyPlan] generation).
class SmartCoachEngine {
  const SmartCoachEngine();

  /// Highest-priority adult review that is due across every surah.
  SmartCoachRecommendation? recommendAdultDueReview(
    Iterable<AyahReviewRecord> reviewRecords, {
    DateTime? now,
  }) {
    final operationNow = (now ?? DateTime.now()).toUtc();
    final records = reviewRecords
        .where(ReviewRecordFilters.isAdultCompatible)
        .toList();

    final weakDue = records.where((record) {
      final classification = record.classifyAt(operationNow);
      return classification.isDue &&
          record.lastRating == PerformanceRating.weak &&
          !classification.isMemorized;
    }).toList()..sort(_compareWeakDue);
    if (weakDue.isNotEmpty) {
      return _ayahRecommendation(
        kind: SmartCoachRecommendationKind.reviewWeakAyah,
        explanationCode: SmartCoachExplanationCode.weakAyahDue,
        record: weakDue.first,
        routeBuilder: _v2SessionRoute,
      );
    }

    final dueNear = records.where((record) {
      final classification = record.classifyAt(operationNow);
      return classification.isDue && classification.isNearRevision;
    }).toList()..sort(_compareNearFarDue);
    if (dueNear.isNotEmpty) {
      return _ayahRecommendation(
        kind: SmartCoachRecommendationKind.reviewDueNear,
        explanationCode: SmartCoachExplanationCode.nearRevisionDue,
        record: dueNear.first,
      );
    }

    final dueFar = records.where((record) {
      final classification = record.classifyAt(operationNow);
      return classification.isDue && classification.isFarRevision;
    }).toList()..sort(_compareNearFarDue);
    if (dueFar.isNotEmpty) {
      return _ayahRecommendation(
        kind: SmartCoachRecommendationKind.reviewDueFar,
        explanationCode: SmartCoachExplanationCode.farRevisionDue,
        record: dueFar.first,
      );
    }

    final memorizedDue = records.where((record) {
      return record.classifyAt(operationNow).isMemorizedDue;
    }).toList()..sort(ReviewRecordFilters.compareMemorizedDue);
    if (memorizedDue.isNotEmpty) {
      return _ayahRecommendation(
        kind: SmartCoachRecommendationKind.memorizedReviewDue,
        explanationCode: SmartCoachExplanationCode.memorizedRetentionDue,
        record: memorizedDue.first,
        routeBuilder: _v2SessionRoute,
      );
    }

    return null;
  }

  SmartCoachRecommendation? recommend(
    MemorizationSnapshot snapshot, {
    DateTime? now,
  }) {
    final operationNow = (now ?? DateTime.now()).toUtc();
    if (snapshot.profile.isChild) {
      return _kidsRecommendation(snapshot);
    }
    if (snapshot.profile.isAdult) {
      final memPlusRec =
          _adultMemPlusRecommendation(snapshot, operationNow) ??
          _continueV2SessionRecommendation(snapshot);
      if (memPlusRec != null) return memPlusRec;
    }
    return null;
  }

  SmartCoachRecommendation? _adultMemPlusRecommendation(
    MemorizationSnapshot snapshot,
    DateTime now,
  ) {
    final dueReview = recommendAdultDueReview(snapshot.reviewRecords, now: now);
    if (dueReview != null) return dueReview;

    // ── Priority 5 & 6: Daily Plan ─────────────────────────────────────────
    final plan = snapshot.cachedDailyPlan;
    if (plan != null && plan.totalItems > 0) {
      final pendingNew = plan.newAyahs
          .where((a) => !plan.isAyahCompleted(a.surahId, a.ayahNumber))
          .toList();
      final pendingCount = plan.requiredAyahs
          .where((a) => !plan.isAyahCompleted(a.surahId, a.ayahNumber))
          .length;

      // Priority 5: Continue incomplete daily plan
      // P0 hotfix: use requiredCompletedCount so retention-only completions
      // do not falsely trigger the "continue" card.
      if (plan.requiredCompletedCount > 0 && pendingCount > 0) {
        final firstPending = PendingAyahResolver.firstPendingPlanTarget(plan);
        if (firstPending == null) return null;
        return SmartCoachRecommendation(
          kind: SmartCoachRecommendationKind.continueDailyPlan,
          explanationCode: SmartCoachExplanationCode.continueDailyPlan,
          route: _v2SessionRoute(
            firstPending.surahId,
            firstPending.ayahNumber,
            intent: LearningIntent.memorize,
          ),
          surahId: firstPending.surahId,
          startAyah: firstPending.ayahNumber,
          completedCount: plan.requiredCompletedCount,
          totalCount: plan.requiredCompletedCount + pendingCount,
        );
      }

      // Priority 6: New ayahs in daily plan
      if (pendingNew.isNotEmpty) {
        return SmartCoachRecommendation(
          kind: SmartCoachRecommendationKind.memorizeNewAyahs,
          explanationCode: SmartCoachExplanationCode.newAyahsAvailable,
          route: _v2SessionRoute(
            plan.surahId,
            pendingNew.first.ayahNumber,
            intent: LearningIntent.memorize,
          ),
          surahId: plan.surahId,
          startAyah: pendingNew.first.ayahNumber,
          endAyah: pendingNew.last.ayahNumber,
        );
      }
    }

    return null;
  }

  // ── Priority 7: Continue V2 Session ─────────────────────────────────────────
  SmartCoachRecommendation? _continueV2SessionRecommendation(
    MemorizationSnapshot snapshot,
  ) {
    final loc = snapshot.lastRestorableLocation;
    if (loc != null && loc.startsWith('/memorization-v2/session')) {
      final uri = Uri.tryParse(loc);
      final surahIdStr = uri?.queryParameters['surahId'];
      final surahId = surahIdStr != null ? int.tryParse(surahIdStr) : null;
      return SmartCoachRecommendation(
        kind: SmartCoachRecommendationKind.continueV2Session,
        explanationCode: SmartCoachExplanationCode.continueV2Session,
        route: loc,
        surahId: surahId,
      );
    }
    return null;
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
        : _v2SessionRoute(record.surahId, record.ayahNumber);
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

  static String _v2SessionRoute(
    int surahId,
    int startAyah, {
    LearningIntent intent = LearningIntent.review,
  }) {
    final launchContext = LearningLaunchContext(
      ayah: AyahReference(surahId: surahId, ayahNumber: startAyah),
      intent: intent,
      origin: LearningOrigin.smartCoach,
    );
    return Uri(
      path: '/memorization-v2/session',
      queryParameters: launchContext.toRouteQuery(),
    ).toString();
  }

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
