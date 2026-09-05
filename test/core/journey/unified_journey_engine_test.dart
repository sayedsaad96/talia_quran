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
    test('resume remains primary when an active Khatmah is available', () {
      const input = UnifiedJourneyInput(
        lastRestorableLocation: '/quran/page/18',
        khatmahCandidate: KhatmahJourneyCandidate(
          route: '/quran/page/42?mode=khatmah',
        ),
      );
      final result = engine.resolve(input);
      expect(result.primary.route, '/quran/page/18');
      expect(result.primary.priority, UnifiedJourneyPriority.p1ActiveSession);
    });

    test(
      'overdue review remains primary when an active Khatmah is available',
      () {
        const input = UnifiedJourneyInput(
          hasReviewBacklog: true,
          overdueAyahs: 3,
          khatmahCandidate: KhatmahJourneyCandidate(
            route: '/quran/page/42?mode=khatmah',
          ),
        );
        final result = engine.resolve(input);
        expect(result.primary.route, '/memorization');
        expect(result.primary.priority, UnifiedJourneyPriority.p3ReviewBacklog);
      },
    );

    test('reading goal prioritizes active Khatmah before daily wird', () {
      const input = UnifiedJourneyInput(
        userGoal: 'reading',
        hasDailyWird: true,
        dailyWirdPageNumber: 12,
        khatmahCandidate: KhatmahJourneyCandidate(
          route: '/quran/page/42?mode=khatmah',
        ),
      );
      final result = engine.resolve(input);
      expect(result.primary.route, '/quran/page/42?mode=khatmah');
      expect(
        result.primary.actionType,
        UnifiedJourneyActionType.khatmahReading,
      );
      expect(result.secondary?.route, '/quran/page/12');
    });

    test('memorization goal prioritizes Smart Coach before active Khatmah', () {
      const input = UnifiedJourneyInput(
        userGoal: 'memorization',
        hasSmartPlan: true,
        smartPlanRoute: '/memorization/coach',
        khatmahCandidate: KhatmahJourneyCandidate(
          route: '/quran/page/42?mode=khatmah',
        ),
      );
      final result = engine.resolve(input);
      expect(result.primary.route, '/memorization/coach');
      expect(result.primary.actionType, UnifiedJourneyActionType.smartPlan);
      expect(result.secondary?.route, '/quran/page/42?mode=khatmah');
    });

    test(
      'does not duplicate a primary destination as its secondary action',
      () {
        const input = UnifiedJourneyInput(
          hasSmartPlan: true,
          smartPlanRoute: '/quran/page/42?mode=khatmah',
          khatmahCandidate: KhatmahJourneyCandidate(
            route: '/quran/page/42?mode=khatmah',
          ),
        );
        final result = engine.resolve(input);
        expect(result.primary.route, '/quran/page/42?mode=khatmah');
        expect(result.secondary?.route, isNot(result.primary.route));
        expect(result.secondary?.route, '/quran');
      },
    );

    test('child mission remains ahead of adult journey candidates', () {
      const input = UnifiedJourneyInput(
        isKids: true,
        hasSmartPlan: true,
        smartPlanRoute: '/memorization/coach',
        khatmahCandidate: KhatmahJourneyCandidate(
          route: '/quran/page/42?mode=khatmah',
        ),
      );
      final result = engine.resolve(input);
      expect(result.primary.route, '/memorization');
      expect(result.primary.source, 'KidsMode');
    });

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
      const input = UnifiedJourneyInput(isKids: true);

      final result = engine.evaluate(input);

      expect(result.priority, UnifiedJourneyPriority.p6FreeExploration);
      expect(result.intent, JourneyIntent.explore);
    });

    test('Priority 6: Azkar Goal Fallback -> azkar', () {
      const input = UnifiedJourneyInput(userGoal: 'azkar');

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
