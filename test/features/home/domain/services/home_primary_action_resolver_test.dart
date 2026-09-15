import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/home/domain/services/home_primary_action_resolver.dart';

void main() {
  const resolver = HomePrimaryActionResolver();

  group('HomePrimaryActionResolver', () {
    test('active khatmah (continueRecitation) always wins', () {
      for (final flagOn in [true, false]) {
        for (final priority in [...UnifiedJourneyPriority.values, null]) {
          expect(
            resolver.resolve(
              unifiedJourneyEnabled: flagOn,
              hasContinueRecitation: true,
              heroPriority: priority,
            ),
            HomePrimaryActionKind.khatmahContinue,
            reason: 'flagOn=$flagOn priority=$priority',
          );
        }
      }
    });

    test('flag on + p1..p4 keeps the journey hero', () {
      for (final priority in [
        UnifiedJourneyPriority.p1ActiveSession,
        UnifiedJourneyPriority.p2CriticalAlert,
        UnifiedJourneyPriority.p3ReviewBacklog,
        UnifiedJourneyPriority.p4SmartPlan,
      ]) {
        expect(
          resolver.resolve(
            unifiedJourneyEnabled: true,
            hasContinueRecitation: false,
            heroPriority: priority,
          ),
          HomePrimaryActionKind.journeyHero,
          reason: 'priority=$priority',
        );
      }
    });

    test('flag on + p5/p6/no-action invites starting a khatmah', () {
      for (final priority in [
        UnifiedJourneyPriority.p5DailyGoal,
        UnifiedJourneyPriority.p6FreeExploration,
        null,
      ]) {
        expect(
          resolver.resolve(
            unifiedJourneyEnabled: true,
            hasContinueRecitation: false,
            heroPriority: priority,
          ),
          HomePrimaryActionKind.startKhatmah,
          reason: 'priority=$priority',
        );
      }
    });

    test('flag off without khatmah defers to the legacy chain downstream', () {
      expect(
        resolver.resolve(
          unifiedJourneyEnabled: false,
          hasContinueRecitation: false,
          heroPriority: UnifiedJourneyPriority.p1ActiveSession,
        ),
        HomePrimaryActionKind.startKhatmah,
      );
    });

    test('active Khatmah keeps an urgent review immediately actionable', () {
      const urgentReview = UnifiedJourneyAction(
        route:
            '/memorization-v2/session?surahId=2&ayahNumber=255&intent=review&origin=smartCoach',
        priority: UnifiedJourneyPriority.p2CriticalAlert,
        source: 'SmartCoach',
        actionType: UnifiedJourneyActionType.criticalAlert,
        intent: JourneyIntent.review,
      );

      expect(
        resolver.shouldShowUrgentJourneyBelowKhatmah(
          unifiedJourneyEnabled: true,
          hasContinueRecitation: true,
          heroAction: urgentReview,
        ),
        isTrue,
      );
      expect(
        resolver.shouldShowUrgentJourneyBelowKhatmah(
          unifiedJourneyEnabled: true,
          hasContinueRecitation: true,
          heroAction: const UnifiedJourneyAction(
            route: '/quran/page/12',
            priority: UnifiedJourneyPriority.p5DailyGoal,
            source: 'DailyWird',
            actionType: UnifiedJourneyActionType.dailyReading,
            intent: JourneyIntent.reading,
          ),
        ),
        isFalse,
      );
    });
  });
}
