import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';

void main() {
  testWidgets('Sprint 1 English localization renders target copy', (
    tester,
  ) async {
    await tester.pumpWidget(const _L10nTestApp(locale: Locale('en')));

    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.text('Your custom plan'), findsOneWidget);
    expect(find.text('Check answer'), findsOneWidget);
    expect(find.text('What happens next?'), findsOneWidget);
    expect(find.text('Reward for the child'), findsOneWidget);
    expect(find.text('Parent / Guardian Tools'), findsOneWidget);
  });

  testWidgets('Sprint 1 Arabic localization renders target copy', (
    tester,
  ) async {
    await tester.pumpWidget(const _L10nTestApp(locale: Locale('ar')));

    expect(find.text('خطتك اليومية'), findsOneWidget);
    expect(find.text('خطتك المخصصة'), findsOneWidget);
    expect(find.text('تحقق من الإجابة'), findsOneWidget);
    expect(find.text('ماذا سيحدث بعد ذلك؟'), findsOneWidget);
    expect(find.text('مكافأة للطفل'), findsOneWidget);
    expect(find.text('أدوات ولي الأمر'), findsOneWidget);
  });

  test('Sprint 1 target screens do not contain Arabic hardcoded literals', () {
    final targetFiles = [
      'lib/features/memorization_plus/presentation/pages/daily_plan_page.dart',
      'lib/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart',
      'lib/features/memorization_plus/presentation/pages/quiz_page.dart',
      'lib/features/memorization_plus/presentation/pages/path_selection_page.dart',
      'lib/features/memorization_plus/presentation/pages/parent_dashboard_page.dart',
    ];
    final arabicScript = RegExp(r'[\u0600-\u06FF]');

    for (final path in targetFiles) {
      final content = File(path).readAsStringSync();
      expect(
        arabicScript.hasMatch(content),
        isFalse,
        reason: '$path contains Arabic-script source literals',
      );
    }
  });
}

class _L10nTestApp extends StatelessWidget {
  const _L10nTestApp({required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Directionality(
            textDirection: locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Scaffold(
              body: Column(
                children: [
                  Text(l10n.dailyPlanHeaderTitle),
                  Text(l10n.customPlanTitle),
                  Text(l10n.quizCheckAnswer),
                  Text(l10n.memorizationPathConfirmTitle),
                  Text(l10n.parentDashboardRemoteRewardTitle),
                  Text(l10n.homeParentToolsTitle),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
