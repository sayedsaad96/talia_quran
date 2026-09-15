import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/core/journey/unified_journey_engine.dart';
import 'package:talia_quran/core/journey/unified_journey_input.dart';
void main() {
  group('Home coach coherence', () {
    const engine = UnifiedJourneyEngine();

    test('weak review remains actionable while daily wird is an alternative', () {
      const exactCoachRoute =
          '/memorization-v2/session?surahId=2&ayahNumber=255&intent=review&origin=smartCoach';
      final actions = engine.evaluateAll(
        const UnifiedJourneyInput(
          hasSmartPlan: true,
          isSmartPlanReview: true,
          smartPlanRoute: exactCoachRoute,
          hasDailyWird: true,
          dailyWirdPageNumber: 12,
        ),
      );

      expect(actions.first.priority, UnifiedJourneyPriority.p4SmartPlan);
      final route = Uri.parse(actions.first.route);
      expect(route.queryParameters['surahId'], '2');
      expect(route.queryParameters['ayahNumber'], '255');
      expect(route.queryParameters['intent'], 'review');
      expect(route.queryParameters['origin'], 'smartCoach');
      expect(
        actions.any(
          (action) =>
              action.priority == UnifiedJourneyPriority.p5DailyGoal &&
              action.route == '/quran/page/12',
        ),
        isTrue,
      );
    });
  });
}
