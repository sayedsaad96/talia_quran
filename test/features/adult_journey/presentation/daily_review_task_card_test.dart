import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_suggestion.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/daily_review_task.dart';
import 'package:talia_quran/features/adult_journey/presentation/widgets/daily_review_task_card.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'adult_journey_test_harness.dart';

void main() {
  for (final locale in ['ar', 'en']) {
    testWidgets('single review has no overflow at 200% in $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const action = UnifiedJourneyAction(
        route: '/memorization/review',
        priority: UnifiedJourneyPriority.p3ReviewBacklog,
        source: 'fixture',
        actionType: UnifiedJourneyActionType.reviewBacklog,
        intent: JourneyIntent.review,
      );
      const decision = DailyReviewTaskDecision(
        status: DailyReviewTaskStatus.ready,
        ownerId: 'a',
        localDate: '2026-10-31',
        decisionKey: 'fixture',
        suggestion: AdultJourneySuggestion(
          action: action,
          launchKind: AdultJourneyLaunchKind.review,
          reason: AdultJourneySuggestionReason.urgent,
          estimatedMinutes: 6,
          exceedsBudget: true,
        ),
      );
      await tester.pumpWidget(
        adultTestApp(
          locale: locale,
          textScale: 2,
          home: SingleChildScrollView(
            child: DailyReviewTaskCard(
              decision: decision,
              skin: HomeSkin.forBrightness(Brightness.light),
              onStart: () {},
              onOtherOptions: () {},
              onChangeTime: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('adult_change_time')), findsOneWidget);
    });
  }
  testWidgets(
    'an over-budget review stays available with a change-time choice',
    (tester) async {
      var starts = 0;
      var changes = 0;
      const action = UnifiedJourneyAction(
        route: '/memorization/review',
        priority: UnifiedJourneyPriority.p3ReviewBacklog,
        source: 'test',
        actionType: UnifiedJourneyActionType.reviewBacklog,
        intent: JourneyIntent.review,
      );
      const decision = DailyReviewTaskDecision(
        status: DailyReviewTaskStatus.ready,
        ownerId: 'a',
        localDate: '2026-10-31',
        decisionKey: 'key',
        suggestion: AdultJourneySuggestion(
          action: action,
          launchKind: AdultJourneyLaunchKind.review,
          reason: AdultJourneySuggestionReason.urgent,
          estimatedMinutes: 6,
          exceedsBudget: true,
        ),
      );
      await tester.pumpWidget(
        adultTestApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyReviewTaskCard(
                decision: decision,
                skin: HomeSkin.forBrightness(Brightness.light),
                onStart: () => starts++,
                onOtherOptions: () {},
                onChangeTime: () => changes++,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('About 6 min'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('adult_change_time')));
      await tester.tap(find.text('Continue task'));
      expect(changes, 1);
      expect(starts, 1);
    },
  );
  testWidgets('no due review does not offer completion', (tester) async {
    const decision = DailyReviewTaskDecision(
      status: DailyReviewTaskStatus.noDueReview,
      ownerId: 'a',
      localDate: '2026-10-31',
    );
    await tester.pumpWidget(
      adultTestApp(
        home: Scaffold(
          body: DailyReviewTaskCard(
            decision: decision,
            skin: HomeSkin.forBrightness(Brightness.light),
            onStart: () {},
            onOtherOptions: () {},
            onChangeTime: () {},
          ),
        ),
      ),
    );
    expect(find.text('No reviews are due now.'), findsOneWidget);
    expect(find.text('Continue task'), findsNothing);
  });
}
