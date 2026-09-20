import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_micro_review_card.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';

AyahReviewRecord _record(int surahId, int ayahNumber) {
  final now = DateTime(2025, 9, 19);
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: 4,
    intervalDays: 7,
    lastReviewedAt: now.subtract(const Duration(days: 10)),
    nextReviewDate: now.add(const Duration(days: 3)),
    totalReviews: 3,
    lastRating: PerformanceRating.average,
  );
}

void main() {
  Widget harness({AyahReviewRecord? record}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeMicroReviewCard(
            skin: HomeSkin.forBrightness(Brightness.light),
            record: record,
          ),
        ),
      ),
    );
  }

  testWidgets('renders the hidden active-recall card with actions',
      (tester) async {
    await tester.pumpWidget(harness(record: _record(2, 255)));
    await tester.pumpAndSettle();

    expect(find.text('Memory flash'), findsOneWidget);
    expect(
      find.text('From your older memorization — do you still recall it?'),
      findsOneWidget,
    );
    // The reference is shown while the ayah itself stays hidden (it appears
    // in both the hidden box and the footer row).
    expect(find.text('Surah Al-Baqarah · Ayah 255'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('hidden')),
      findsOneWidget,
      reason: 'active recall — the ayah text is hidden until tapped',
    );
    expect(find.byKey(const Key('home_micro_review_recite')), findsOneWidget);
  });

  testWidgets('tapping the hidden card reveals the ayah', (tester) async {
    await tester.pumpWidget(harness(record: _record(2, 255)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hidden')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('revealed')), findsOneWidget);
    expect(find.byKey(const ValueKey('hidden')), findsNothing);
  });

  testWidgets('renders nothing when the user has no memorized ayahs',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Memory flash'), findsNothing);
  });

}
