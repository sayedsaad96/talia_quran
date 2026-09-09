import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/app_localizations_ar.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/widgets/daily_wird_card.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  test('homeDailyWirdSurahPage keeps page then surah argument order', () {
    final en = AppLocalizationsEn();
    final ar = AppLocalizationsAr();
    expect(en.homeDailyWirdSurahPage('431', 'Al-An\'am'), 'Surah Al-An\'am — Page 431');
    expect(ar.homeDailyWirdSurahPage('431', 'الأنعام'), 'سورة الأنعام — صفحة 431');
  });

  testWidgets('DailyWirdCard renders page then surah, not swapped', (tester) async {
    const surah = Surah(
      id: 6,
      nameAr: 'الأنعام',
      nameEn: 'Al-An\'am',
      ayahCount: 165,
      juz: 7,
      type: 'meccan',
      page: 128,
    );
    final state = HomeLoaded(
      progress: const OverallProgress(
        memorizedAyahs: 1,
        totalAyahs: 6236,
        memorizedSurahs: 0,
        totalSurahs: 114,
        memorizedJuz: 0,
        totalJuz: 30,
        readAyahs: 1,
        readSurahs: 1,
        readJuz: 0,
        streakDays: 1,
        lastActiveDate: null,
        achievements: [],
        readPagesCount: 1,
        totalQuranPages: 604,
        learningAyahs: 0,
        reviewAyahs: 0,
      ),
      greeting: 'morning',
      dailyWirdPageDetail: const QuranPageDetail(
        pageNumber: 128,
        ayahs: [],
        surahs: [surah],
      ),
      activityStartDate: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DailyWirdCard(state: state, isDark: false)),
      ),
    );

    expect(find.text('Surah Al-An\'am — Page 128'), findsOneWidget);
    expect(find.textContaining('Surah 128'), findsNothing);
  });
}
