import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_state.dart';
import 'package:talia_quran/features/adult_journey/presentation/widgets/adult_today_budget_card.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';

import 'adult_journey_test_harness.dart';

AdultJourneyPreferences _withMinutes(int minutes, {AdultJourneyGoal? goal}) =>
    AdultJourneyPreferences(
      goal: goal,
      profileCompleted: goal != null,
      todayLocalDate: adultTestToday,
      todayMinutes: minutes,
    );

const _reviewBacklog = UnifiedJourneyAction(
  route: '/memorization-v2/session?review=1',
  priority: UnifiedJourneyPriority.p3ReviewBacklog,
  source: 'test',
  actionType: UnifiedJourneyActionType.reviewBacklog,
  intent: JourneyIntent.review,
);

const _reading = UnifiedJourneyAction(
  route: '/quran/daily',
  priority: UnifiedJourneyPriority.p5DailyGoal,
  source: 'test',
  actionType: UnifiedJourneyActionType.dailyReading,
  intent: JourneyIntent.reading,
);

void main() {
  late AdultCubitFixture fixture;

  Future<void> pumpCard(
    WidgetTester tester, {
    AdultJourneyPreferences? preferences,
    List<UnifiedJourneyAction> actions = const [],
    String locale = 'en',
    double textScale = 1.0,
    Future<void> Function(BuildContext, String)? openRoute,
  }) async {
    fixture = AdultCubitFixture(
      preferences: preferences ?? AdultJourneyPreferences.empty,
    );
    addTearDown(fixture.cubit.close);
    await fixture.cubit.refreshContext(fixture.context(actions: actions));
    await tester.pumpWidget(
      adultTestApp(
        locale: locale,
        textScale: textScale,
        home: BlocProvider<AdultJourneyCubit>.value(
          value: fixture.cubit,
          child: SingleChildScrollView(
            child: BlocBuilder<AdultJourneyCubit, AdultJourneyState>(
              builder: (context, state) => AdultTodayBudgetCard(
                state: state,
                skin: HomeSkin.forBrightness(Brightness.light),
                openRoute: openRoute,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('offers only 5, 10 and 20 with nothing selected', (tester) async {
    await pumpCard(tester);

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    for (final m in [5, 10, 20]) {
      expect(find.byKey(ValueKey('adult_minutes_$m')), findsOneWidget);
    }
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);
    final selected = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .where((c) => c.selected);
    expect(selected, isEmpty, reason: 'no default time');
    expect(find.text('Fits your time today'), findsNothing);
  });

  testWidgets('choosing a time stores it and shows approximate suggestions', (
    tester,
  ) async {
    await pumpCard(tester, actions: const [_reading]);
    fixture.updateReturns(AdultJourneySaveResult.saved(_withMinutes(10)));

    await tester.tap(find.byKey(const ValueKey('adult_minutes_10')));
    await tester.pumpAndSettle();

    final command =
        verify(() => fixture.update(any(), captureAny())).captured.single
            as SetAdultToday;
    expect(command.minutes, 10);
    expect(command.localDate, adultTestToday);
    expect(find.text('Fits your time today'), findsOneWidget);
    expect(find.textContaining('About 4 min'), findsOneWidget);
  });

  testWidgets('every estimate is labelled approximate in Arabic', (
    tester,
  ) async {
    await pumpCard(
      tester,
      preferences: _withMinutes(10),
      actions: const [_reading],
      locale: 'ar',
    );

    expect(find.textContaining('تقريبًا'), findsWidgets);
    expect(find.text('العودة للاقتراحات المعتادة'), findsOneWidget);
  });

  testWidgets('a protected item over budget stays with a note and change', (
    tester,
  ) async {
    await pumpCard(
      tester,
      preferences: _withMinutes(5),
      actions: const [_reviewBacklog, _reading],
    );

    expect(find.byKey(const ValueKey('adult_exceeds_note')), findsOneWidget);
    expect(find.textContaining('About 6 min'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('adult_change_time')));
    await tester.pump();
    expect(find.byType(ChoiceChip), findsNWidgets(3));
  });

  testWidgets('a failed time save is shown and keeps the chips', (
    tester,
  ) async {
    await pumpCard(tester, actions: const [_reading]);
    fixture.updateReturns(
      const AdultJourneySaveResult.failed(AdultJourneySaveFailure.storage),
    );

    await tester.tap(find.byKey(const ValueKey('adult_minutes_5')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('adult_today_error')), findsOneWidget);
    expect(find.byKey(const ValueKey('adult_minutes_5')), findsOneWidget);
    expect(find.text('Fits your time today'), findsNothing);
  });

  testWidgets('a missing estimate says the duration is unavailable', (
    tester,
  ) async {
    await pumpCard(
      tester,
      preferences: _withMinutes(10, goal: AdultJourneyGoal.memorization),
    );

    expect(find.textContaining('Duration unavailable'), findsWidgets);
    expect(
      find.text('Start by setting up a memorization plan'),
      findsOneWidget,
    );
  });

  testWidgets('back to the usual suggestions clears only today', (
    tester,
  ) async {
    await pumpCard(
      tester,
      preferences: _withMinutes(10),
      actions: const [_reading],
    );
    fixture.updateReturns(
      const AdultJourneySaveResult.saved(AdultJourneyPreferences()),
    );

    await tester.tap(find.byKey(const ValueKey('adult_back_to_usual')));
    await tester.pumpAndSettle();

    verify(
      () => fixture.update(any(), any(that: isA<ClearAdultToday>())),
    ).called(1);
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.text('Fits your time today'), findsNothing);
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('fits 320 px at 200% text ()', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpCard(
        tester,
        preferences: _withMinutes(5),
        actions: const [_reviewBacklog, _reading],
        locale: locale,
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a double tap navigates once', (tester) async {
    final gate = Completer<void>();
    final opened = <String>[];
    await pumpCard(
      tester,
      preferences: _withMinutes(10),
      actions: const [_reading],
      openRoute: (_, route) {
        opened.add(route);
        return gate.future;
      },
    );

    await tester.tap(find.byKey(const ValueKey('adult_suggestion_0')));
    await tester.tap(find.byKey(const ValueKey('adult_suggestion_0')));
    await tester.pump();
    gate.complete();
    await tester.pump();

    expect(opened, ['/quran/daily']);
  });
}
