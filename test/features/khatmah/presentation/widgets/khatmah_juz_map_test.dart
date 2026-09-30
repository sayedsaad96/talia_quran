import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_juz_map.dart';

void main() {
  final plan = KhatmahPlan(
    id: 'p',
    title: KhatmahPlan.defaultTitle,
    completedPages: {for (var p = 1; p <= 21; p++) p, 22, 30},
    targetPagesPerDay: 5,
    targetDays: 121,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 5, 1),
  );

  Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
    theme: theme ?? AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('shows 30 juz and opens the first unread page', (tester) async {
    int? opened;
    await tester.pumpWidget(
      host(KhatmahJuzMap(plan: plan, onOpenPage: (page) => opened = page)),
    );

    for (var juz = 1; juz <= 30; juz++) {
      expect(find.byKey(Key('khatmah_juz_cell_$juz')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('khatmah_juz_cell_2')));
    expect(opened, 23);
    expect(find.bySemanticsLabel(RegExp('Juz 1: 21 of 21')), findsOneWidget);
  });

  testWidgets('a disabled map ignores taps', (tester) async {
    int? opened;
    await tester.pumpWidget(
      host(
        KhatmahJuzMap(
          plan: plan,
          enabled: false,
          onOpenPage: (page) => opened = page,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('khatmah_juz_cell_2')));
    expect(opened, isNull);
  });

  testWidgets('renders in the dark theme', (tester) async {
    await tester.pumpWidget(
      host(
        KhatmahJuzMap(plan: plan, onOpenPage: (_) {}),
        theme: AppTheme.dark,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
