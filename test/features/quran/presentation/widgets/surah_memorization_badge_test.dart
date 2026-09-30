import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/surah_memorization_status.dart';
import 'package:talia_quran/features/quran/presentation/widgets/surah_memorization_badge.dart';

/// N17: the surah list badge for the learner's memorization status.
void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('memorized surah', (tester) async {
    await tester.pumpWidget(
      host(const SurahMemorizationBadge(SurahMemorizationStatus.memorized)),
    );
    expect(find.text('محفوظة'), findsOneWidget);
  });

  testWidgets('surah in progress', (tester) async {
    await tester.pumpWidget(
      host(const SurahMemorizationBadge(SurahMemorizationStatus.inProgress)),
    );
    expect(find.text('قيد الحفظ'), findsOneWidget);
  });
}
