import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/core/journey/unified_journey_engine.dart';
import 'package:talia_quran/core/journey/unified_journey_input.dart';
import 'package:talia_quran/core/memorization/smart_coach_recommendation.dart';

void main() {
  group('hero vs coach coherence (Sprint 3.1)', () {
    const engine = UnifiedJourneyEngine();

    UnifiedJourneyAction? resolveHero({
      required UnifiedJourneyAction action,
      SmartCoachRecommendationKind? coachKind,
    }) {
      if (coachKind == null) return action;
      final coachUrgent = switch (coachKind) {
        SmartCoachRecommendationKind.reviewWeakAyah ||
        SmartCoachRecommendationKind.reviewDueNear ||
        SmartCoachRecommendationKind.reviewDueFar ||
        SmartCoachRecommendationKind.memorizedReviewDue ||
        SmartCoachRecommendationKind.reviewWeakAyah => true,
        _ => false,
      };
      if (!coachUrgent) return action;
      if (action.priority == UnifiedJourneyPriority.p5DailyGoal ||
          action.priority == UnifiedJourneyPriority.p6FreeExploration) {
        return null;
      }
      return action;
    }

    test('daily wird hero suppressed when coach has weak ayah review', () {
      const input = UnifiedJourneyInput(
        hasSmartPlan: true,
        isSmartPlanReview: true,
        hasDailyWird: true,
        dailyWirdPageNumber: 12,
      );

      final hero = engine.evaluate(input);
      expect(hero.priority, UnifiedJourneyPriority.p4SmartPlan);

      final dailyOnly = engine.evaluate(
        const UnifiedJourneyInput(hasDailyWird: true, dailyWirdPageNumber: 12),
      );
      expect(dailyOnly.priority, UnifiedJourneyPriority.p5DailyGoal);

      final resolved = resolveHero(
        action: dailyOnly,
        coachKind: SmartCoachRecommendationKind.reviewWeakAyah,
      );
      expect(resolved, isNull);
    });
  });
}
