import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/core/journey/unified_journey_input.dart';
import 'package:talia_quran/core/journey/unified_journey_engine.dart';

void main() {
  late UnifiedJourneyEngine engine;

  setUp(() {
    engine = const UnifiedJourneyEngine();
  });

  group('UnifiedJourneyEngine Priority and Intent Resolution', () {
    test('Priority 1: Active Session -> resume', () {
      const input = UnifiedJourneyInput(
        lastRestorableLocation: '/some_route',
        hasCriticalLearningAlert: true,
        hasReviewBacklog: true,
        overdueAyahs: 200,
        hasSmartPlan: true,
        hasDailyWird: true,
        dailyWirdPageNumber: 1,
      );

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p1ActiveSession);
      expect(result.intent, JourneyIntent.resume);
      expect(result.route, '/some_route');
    });

    test('Priority 2: Critical Alert -> review', () {
      const input = UnifiedJourneyInput(
        hasCriticalLearningAlert: true,
        hasReviewBacklog: true,
        overdueAyahs: 200,
        hasSmartPlan: true,
      );

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p2CriticalAlert);
      expect(result.intent, JourneyIntent.review);
    });

    test('Priority 3: Review Backlog -> review', () {
      const input = UnifiedJourneyInput(
        hasReviewBacklog: true,
        overdueAyahs: 20,
        hasSmartPlan: true,
        hasDailyWird: true,
      );

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p3ReviewBacklog);
      expect(result.intent, JourneyIntent.review);
    });

    test('Priority 4: Smart Plan (Review) -> review', () {
      const input = UnifiedJourneyInput(
        hasSmartPlan: true,
        isSmartPlanReview: true,
      );

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p4SmartPlan);
      expect(result.intent, JourneyIntent.review);
    });
    
    test('Priority 4: Smart Plan (Memorize) -> memorize', () {
      const input = UnifiedJourneyInput(
        hasSmartPlan: true,
        isSmartPlanReview: false,
      );

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p4SmartPlan);
      expect(result.intent, JourneyIntent.memorize);
    });

    test('Priority 5: Daily Wird -> reading', () {
      const input = UnifiedJourneyInput(
        hasDailyWird: true,
        dailyWirdPageNumber: 5,
        isKids: true,
      );

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p5DailyGoal);
      expect(result.intent, JourneyIntent.reading);
      expect(result.route, '/quran/page/5');
    });

    test('Priority 6: Kids Mode Fallback -> explore', () {
      const input = UnifiedJourneyInput(
        isKids: true,
      );

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p6FreeExploration);
      expect(result.intent, JourneyIntent.explore);
    });

    test('Priority 6: Azkar Goal Fallback -> azkar', () {
      const input = UnifiedJourneyInput(
        userGoal: 'azkar',
      );

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p6FreeExploration);
      expect(result.intent, JourneyIntent.azkar);
      expect(result.route, '/azkar');
    });

    test('Priority 6: Default Fallback -> explore', () {
      const input = UnifiedJourneyInput();

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p6FreeExploration);
      expect(result.intent, JourneyIntent.explore);
      expect(result.route, '/quran');
    });
  });
}
