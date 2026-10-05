import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/remote_child_activity.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/child_activity_summary.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  final activity = RemoteChildActivity(
    updatedAt: DateTime.utc(2026, 10, 5, 6, 30),
    dayKey: '2026-10-05',
    currentStreak: 4,
    longestStreak: 11,
    activeDaysLast30: 18,
    totalXp: 1200,
    readPagesCount: 40,
    todayActivityCount: 3,
    todayReadPagesCount: 2,
  );

  testWidgets('a missing snapshot says no data arrived, not zero', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ChildActivitySummary(activity: null)));

    expect(
      find.text("No activity has arrived from the child's device yet"),
      findsOneWidget,
    );
    expect(find.textContaining('Current streak'), findsNothing);
  });

  testWidgets('shows the published streak, active days and pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ChildActivitySummary(
          activity: activity,
          now: DateTime(2026, 10, 5, 12),
        ),
      ),
    );

    expect(find.text('Current streak: 4 · Longest: 11'), findsOneWidget);
    expect(find.text('Active days in the last 30: 18'), findsOneWidget);
    expect(find.text('Pages read: 40 · Today: 2'), findsOneWidget);
    expect(find.textContaining('Last updated:'), findsOneWidget);
  });

  testWidgets('yesterday\'s snapshot does not count as today', (tester) async {
    await tester.pumpWidget(
      app(
        ChildActivitySummary(
          activity: activity,
          now: DateTime(2026, 10, 6, 12),
        ),
      ),
    );

    expect(find.text('Pages read: 40 · Today: 0'), findsOneWidget);
  });
}
