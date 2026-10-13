import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';
import 'package:talia_quran/features/adult_journey/presentation/widgets/adult_journey_setup_sheet.dart';

import 'adult_journey_test_harness.dart';

const _saved = AdultJourneyPreferences(
  goal: AdultJourneyGoal.azkar,
  profileCompleted: true,
);

void main() {
  late AdultCubitFixture fixture;

  setUp(() => fixture = AdultCubitFixture());
  tearDown(() => fixture.cubit.close());

  Future<void> openSheet(
    WidgetTester tester, {
    String locale = 'en',
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) async {
    await fixture.cubit.loadPreferences();
    await tester.pumpWidget(
      adultTestApp(
        locale: locale,
        textScale: textScale,
        brightness: brightness,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAdultJourneySetupSheet(context, fixture.cubit),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers the four goals and three optional experiences', (
    tester,
  ) async {
    await openSheet(tester);

    for (final goal in AdultJourneyGoal.values) {
      expect(find.byKey(ValueKey('adult_goal_${goal.name}')), findsOneWidget);
    }
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('New memorization'), findsOneWidget);
    expect(find.text('Strengthen what I memorized'), findsOneWidget);
    expect(find.text('Azkar'), findsOneWidget);
    for (final e in AdultJourneyExperience.values) {
      expect(
        find.byKey(ValueKey('adult_experience_${e.name}')),
        findsOneWidget,
      );
    }
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('adult_setup_save')),
    );
    expect(save.onPressed, isNull, reason: 'a goal is required');
  });

  testWidgets('does not prefill from user_primary_goal', (tester) async {
    SharedPreferences.setMockInitialValues({'user_primary_goal': 'azkar'});
    await openSheet(tester);

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.where((c) => c.selected), isEmpty);
  });

  testWidgets('saves a goal alone, without an experience', (tester) async {
    fixture.updateReturns(const AdultJourneySaveResult.saved(_saved));
    await openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('adult_goal_azkar')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('adult_setup_save')));
    await tester.pumpAndSettle();

    final command =
        verify(() => fixture.update(any(), captureAny())).captured.single
            as SaveAdultProfile;
    expect(command.goal, AdultJourneyGoal.azkar);
    expect(command.experience, isNull);
    expect(find.byType(AdultJourneySetupSheet), findsNothing);
  });

  testWidgets('experience is optional and can be cleared', (tester) async {
    fixture.updateReturns(const AdultJourneySaveResult.saved(_saved));
    await openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('adult_goal_reading')));
    await tester.tap(find.byKey(const ValueKey('adult_experience_returning')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('adult_experience_returning')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('adult_experience_beginner')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('adult_setup_save')));
    await tester.pumpAndSettle();

    final command =
        verify(() => fixture.update(any(), captureAny())).captured.single
            as SaveAdultProfile;
    expect(command.experience, AdultJourneyExperience.beginner);
  });

  testWidgets('cancel saves nothing', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('adult_goal_reading')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('adult_setup_cancel')));
    await tester.pumpAndSettle();

    verifyNever(() => fixture.update(any(), any()));
    expect(find.byType(AdultJourneySetupSheet), findsNothing);
  });

  testWidgets('failure keeps the choice and retry succeeds', (tester) async {
    fixture.updateReturns(
      const AdultJourneySaveResult.failed(AdultJourneySaveFailure.storage),
    );
    await openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('adult_goal_reading')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('adult_setup_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('adult_setup_error')), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    final reading = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('adult_goal_reading')),
    );
    expect(reading.selected, isTrue, reason: 'selection survives the failure');
    expect(fixture.cubit.state.preferences, AdultJourneyPreferences.empty);

    fixture.updateReturns(const AdultJourneySaveResult.saved(_saved));
    await tester.tap(find.byKey(const ValueKey('adult_setup_save')));
    await tester.pumpAndSettle();

    expect(find.byType(AdultJourneySetupSheet), findsNothing);
    expect(fixture.cubit.state.preferences, _saved);
  });

  testWidgets('a reopened sheet does not show the earlier failure', (
    tester,
  ) async {
    fixture.updateReturns(
      const AdultJourneySaveResult.failed(AdultJourneySaveFailure.storage),
    );
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('adult_goal_reading')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('adult_setup_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('adult_setup_error')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('adult_setup_cancel')));
    await tester.pumpAndSettle();
    expect(fixture.cubit.state.error, isNotNull, reason: 'still in state');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('adult_setup_error')), findsNothing);
  });

  testWidgets('renders Arabic labels', (tester) async {
    await openSheet(tester, locale: 'ar');

    expect(find.text('قراءة'), findsOneWidget);
    expect(find.text('حفظ جديد'), findsOneWidget);
    expect(find.text('تثبيت المحفوظ'), findsOneWidget);
    expect(find.text('أذكار'), findsOneWidget);
    expect(find.text('مبتدئ'), findsOneWidget);
    expect(find.text('مستمر'), findsOneWidget);
    expect(find.text('عائد بعد انقطاع'), findsOneWidget);
  });

  for (final locale in ['ar', 'en']) {
    for (final brightness in Brightness.values) {
      testWidgets('fits 320 px at 200% text ($locale, ${brightness.name})', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await openSheet(
          tester,
          locale: locale,
          textScale: 2.0,
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('adult_setup_save')), findsOneWidget);
      });
    }
  }
}
