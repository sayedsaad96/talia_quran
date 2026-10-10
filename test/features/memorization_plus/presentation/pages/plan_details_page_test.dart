import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/plan_details_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/plan_details_page.dart';
import '../../../../support/plan_details_fixture.dart';

void main() {
  late PlanDetailsFixtureHarness harness;
  late ProgressEventsBus events;
  late PlanDetailsCubit cubit;
  setUp(() {
    harness = PlanDetailsFixtureHarness();
    events = ProgressEventsBus();
    cubit = PlanDetailsCubit(harness.read, events);
  });
  tearDown(() => events.dispose());

  Future<void> pump(WidgetTester tester, {bool arabic = false}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(arabic ? 320 : 600, 850);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(arabic ? 'ar' : 'en'),
        theme: arabic ? AppTheme.dark : AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(arabic ? 1.8 : 1)),
          child: child!,
        ),
        home: PlanDetailsPage(cubitOverride: cubit),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders complete settings and separates remaining, learning and mastery',
    (tester) async {
      await pump(tester);
      expect(find.text('Saved plan'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('plan_details_memorized')))
            .data,
        '1',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('plan_details_remaining')))
            .data,
        '29',
      );
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Being consolidated'), findsWidgets);
      expect(find.text('Your saved settings'), findsOneWidget);
      expect(find.text('Progress by surah'), findsOneWidget);
      expect(find.text('Reviews within this plan'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('plan_details_start_session')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'Arabic narrow dark layout supports enlarged text without overflow',
    (tester) async {
      await pump(tester, arabic: true);
      expect(
        Directionality.of(tester.element(find.text('Saved plan'))),
        TextDirection.rtl,
      );
      await tester.ensureVisible(find.text('التقدم لكل سورة'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a read failure offers retry and never displays fabricated totals',
    (tester) async {
      when(
        () => harness.repository.getCustomPlan(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      await pump(tester);
      expect(find.byKey(const Key('plan_details_memorized')), findsNothing);
      when(
        () => harness.repository.getCustomPlan(),
      ).thenAnswer((_) async => Right(planDetailsFixture().plan));
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('plan_details_memorized')), findsOneWidget);
    },
  );

  testWidgets('no active plan offers creation instead of zero progress', (
    tester,
  ) async {
    when(
      () => harness.repository.getCustomPlan(),
    ).thenAnswer((_) async => const Right(null));
    await pump(tester);
    expect(find.byKey(const Key('plan_details_memorized')), findsNothing);
    expect(find.text('Create your plan'), findsOneWidget);
  });
}
