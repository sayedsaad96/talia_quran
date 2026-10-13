import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';
import 'package:talia_quran/features/adult_journey/domain/services/adult_return_policy.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_state.dart';
import 'package:talia_quran/features/adult_journey/presentation/widgets/adult_return_card.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';

import 'adult_journey_test_harness.dart';

const _absencePrefs = AdultJourneyPreferences(
  returnOfferLocalDate: adultTestToday,
);
const _selfPrefs = AdultJourneyPreferences(
  experience: AdultJourneyExperience.returning,
);

const _light = ValueKey('adult_return_light');
const _choose = ValueKey('adult_return_choose_time');
const _continue = ValueKey('adult_return_continue');

void main() {
  late AdultCubitFixture fixture;

  /// [override] replaces the cubit's state before it reaches the card, to
  /// exercise states the all-flags-on fixture cannot produce.
  Future<void> pumpCard(
    WidgetTester tester, {
    AdultJourneyPreferences preferences = AdultJourneyPreferences.empty,
    String locale = 'en',
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
    AdultJourneyState Function(AdultJourneyState)? override,
  }) async {
    fixture = AdultCubitFixture(preferences: preferences);
    addTearDown(fixture.cubit.close);
    await fixture.cubit.refreshContext(fixture.context());
    await tester.pumpWidget(
      adultTestApp(
        locale: locale,
        textScale: textScale,
        brightness: brightness,
        home: BlocProvider<AdultJourneyCubit>.value(
          value: fixture.cubit,
          child: SingleChildScrollView(
            child: BlocBuilder<AdultJourneyCubit, AdultJourneyState>(
              builder: (context, state) => AdultReturnCard(
                state: override == null ? state : override(state),
                skin: HomeSkin.forBrightness(brightness),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  AdultJourneyState timeOff(AdultJourneyState s) => AdultJourneyState(
    status: s.status,
    preferences: s.preferences,
    localDate: s.localDate,
    returnOffer: s.returnOffer,
    returnTimeActionsEnabled: false,
  );

  Object captured() =>
      verify(() => fixture.update(any(), captureAny())).captured.single
          as Object;

  testWidgets('renders nothing when there is no offer', (tester) async {
    await pumpCard(tester);

    expect(find.byKey(const ValueKey('adult_return_card')), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('absence offer welcomes the user back', (tester) async {
    await pumpCard(tester, preferences: _absencePrefs);

    expect(fixture.cubit.state.returnOffer?.reason, AdultReturnReason.absence);
    expect(
      find.text('Welcome back. Shall we start with a light step?'),
      findsOneWidget,
    );
    expect(find.textContaining('plans and reviews stay'), findsOneWidget);
  });

  testWidgets('self-described offer makes no absence claim', (tester) async {
    for (final locale in ['en', 'ar']) {
      await pumpCard(tester, preferences: _selfPrefs, locale: locale);

      expect(
        fixture.cubit.state.returnOffer?.reason,
        AdultReturnReason.selfDescribed,
      );
      expect(find.textContaining('Welcome back'), findsNothing);
      expect(find.textContaining('برجوعك'), findsNothing);
      expect(
        find.text(
          locale == 'en'
              ? 'Shall we start with a light step?'
              : 'نبدأ بخطوة خفيفة؟',
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('light start sends only StartAdultLightReturn', (tester) async {
    await pumpCard(tester, preferences: _absencePrefs);
    fixture.updateReturns(
      const AdultJourneySaveResult.saved(AdultJourneyPreferences()),
    );

    await tester.tap(find.byKey(_light));
    await tester.pumpAndSettle();

    final command = captured() as StartAdultLightReturn;
    expect(command.localDate, adultTestToday);
    expect(find.byKey(const ValueKey('adult_return_card')), findsNothing);
  });

  testWidgets('choose time sends only DismissAdultReturn', (tester) async {
    await pumpCard(tester, preferences: _absencePrefs);
    fixture.updateReturns(
      const AdultJourneySaveResult.saved(AdultJourneyPreferences()),
    );

    await tester.tap(find.byKey(_choose));
    await tester.pumpAndSettle();

    final command = captured() as DismissAdultReturn;
    expect(command.localDate, adultTestToday);
  });

  testWidgets('continue as usual sends only ContinueAdultAsUsual', (
    tester,
  ) async {
    await pumpCard(tester, preferences: _absencePrefs);
    fixture.updateReturns(
      const AdultJourneySaveResult.saved(AdultJourneyPreferences()),
    );

    await tester.tap(find.byKey(_continue));
    await tester.pumpAndSettle();

    final command = captured() as ContinueAdultAsUsual;
    expect(command.localDate, adultTestToday);
  });

  testWidgets('with time actions off only continue is offered', (tester) async {
    await pumpCard(tester, preferences: _absencePrefs, override: timeOff);

    expect(find.byKey(_continue), findsOneWidget);
    expect(find.byKey(_light), findsNothing);
    expect(find.byKey(_choose), findsNothing);
  });

  testWidgets('a failed save shows the error and keeps the card', (
    tester,
  ) async {
    await pumpCard(tester, preferences: _absencePrefs);
    fixture.updateReturns(
      const AdultJourneySaveResult.failed(AdultJourneySaveFailure.storage),
    );

    await tester.tap(find.byKey(_light));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('adult_return_error')), findsOneWidget);
    expect(find.textContaining('Could not save'), findsOneWidget);
    expect(find.byKey(const ValueKey('adult_return_card')), findsOneWidget);
  });

  testWidgets('buttons are disabled while saving', (tester) async {
    await pumpCard(
      tester,
      preferences: _absencePrefs,
      override: (s) => s.copyWith(isSaving: true),
    );

    for (final key in [_light, _choose, _continue]) {
      final button = tester.widget<ButtonStyleButton>(find.byKey(key));
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('no action navigates', (tester) async {
    await pumpCard(tester, preferences: _absencePrefs);
    fixture.updateReturns(
      const AdultJourneySaveResult.saved(AdultJourneyPreferences()),
    );

    await tester.tap(find.byKey(_light));
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(Navigator.of(tester.element(find.byType(Scaffold))).canPop(), false);
  });

  for (final locale in ['ar', 'en']) {
    for (final brightness in Brightness.values) {
      testWidgets('fits 320 px at 200% text ($locale, $brightness)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final handle = tester.ensureSemantics();

        await pumpCard(
          tester,
          preferences: _absencePrefs,
          locale: locale,
          textScale: 2.0,
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  }
}
