import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_weekly_coaching.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_weekly_coaching_card.dart';

void main() {
  final day = DateTime(2026, 10, 8);

  Future<void> pump(
    WidgetTester tester,
    KidsWeeklyCoaching coaching, {
    Locale locale = const Locale('en'),
  }) => tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: KidsWeeklyCoachingCard(coaching: coaching)),
    ),
  );

  KidsWeeklyCoaching ready({KidsWeeklyCoachingTip? tip}) => KidsWeeklyCoaching(
    status: KidsWeeklyCoachingStatus.ready,
    periodStart: day.subtract(const Duration(days: 6)),
    periodEnd: day,
    sessions: 5,
    activeDays: 3,
    reviews: 2,
    sessionsWithHints: 4,
    tip: tip,
  );

  testWidgets('an incomplete history says the summary is unavailable', (
    tester,
  ) async {
    await pump(
      tester,
      KidsWeeklyCoaching(
        status: KidsWeeklyCoachingStatus.incompleteHistory,
        periodStart: day,
        periodEnd: day,
      ),
    );

    expect(
      find.byKey(const ValueKey('kids-weekly-coaching-unavailable')),
      findsOneWidget,
    );
    expect(find.textContaining('Sessions:'), findsNothing);
  });

  testWidgets('no history shows the empty line, not zeros', (tester) async {
    await pump(
      tester,
      KidsWeeklyCoaching(
        status: KidsWeeklyCoachingStatus.noHistory,
        periodStart: day,
        periodEnd: day,
      ),
    );

    expect(
      find.byKey(const ValueKey('kids-weekly-coaching-empty')),
      findsOneWidget,
    );
  });

  testWidgets('a ready week shows its facts and one tip', (tester) async {
    await pump(tester, ready(tip: KidsWeeklyCoachingTip.listenTogether));

    expect(find.text('Sessions: 5'), findsOneWidget);
    expect(find.text('Active days: 3'), findsOneWidget);
    expect(find.text('Reviews: 2'), findsOneWidget);
    expect(find.text('Sessions with a hint: 4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('kids-weekly-coaching-tip')),
      findsOneWidget,
    );
  });

  testWidgets('renders in Arabic at a narrow width without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(
      tester,
      ready(tip: KidsWeeklyCoachingTip.celebrateEffort),
      locale: const Locale('ar'),
    );

    expect(
      find.byKey(const ValueKey('kids-weekly-coaching-tip')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
