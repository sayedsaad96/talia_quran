import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/home/domain/entities/continue_recitation.dart';
import 'package:talia_quran/features/home/domain/services/continue_recitation_mapper.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  const mapper = ContinueRecitationMapper();
  final now = DateTime(2026, 9, 9, 10);

  const fatiha = Surah(
    id: 1,
    nameAr: 'الفاتحة',
    nameEn: 'Al-Fatihah',
    ayahCount: 7,
    juz: 1,
    type: 'meccan',
    page: 1,
  );

  const page = QuranPageDetail(
    pageNumber: 1,
    surahs: [fatiha],
    ayahs: [
      Ayah(number: 1, surahId: 1, text: 'بِسْمِ', numberInSurah: 1),
      Ayah(number: 7, surahId: 1, text: 'صِرَاطَ', numberInSurah: 7),
    ],
  );

  test('active khatmah uses real daily page target as N of M', () {
    final plan = KhatmahPlan(
      id: 'k1',
      title: KhatmahPlan.defaultTitle,
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: now,
      expectedEndDate: now.add(const Duration(days: 151)),
      dailyTargetDate: now,
      dailyTargetStartPage: 10,
      dailyTargetEndPage: 13,
      completedPages: {for (var page = 1; page <= 11; page++) page},
    );

    final recitation = mapper.map(
      isArabic: true,
      activeKhatmah: plan,
      dailyWirdPageDetail: page,
      now: now,
    );

    expect(recitation, isNotNull);
    expect(recitation!.unit, ContinueRecitationUnit.pages);
    expect(recitation.current, 2);
    expect(recitation.total, 4);
    expect(recitation.percent, 0.5);
    expect(recitation.startAyah, 1);
    expect(recitation.endAyah, 7);
    expect(recitation.surahId, 1);
    expect(recitation.route, '/quran/page/12?mode=khatmah');
  });

  test('does not invent recitation progress from a default wird page', () {
    final recitation = mapper.map(
      isArabic: false,
      dailyWirdPageDetail: page,
      heroAction: const UnifiedJourneyAction(
        route: '/quran/page/1',
        priority: UnifiedJourneyPriority.p5DailyGoal,
        source: 'test',
        actionType: UnifiedJourneyActionType.dailyReading,
        intent: JourneyIntent.reading,
      ),
    );

    expect(recitation, isNull);
  });

  test('resume uses confirmed mushaf pages, not the last ayah printed on the page', () {
    final recitation = mapper.map(
      isArabic: false,
      dailyWirdPageDetail: page,
      lastRestorableLocation: '/quran/page/1',
      confirmedReadPages: 80,
    );

    expect(recitation, isNotNull);
    expect(recitation!.unit, ContinueRecitationUnit.pages);
    expect(recitation.surahName, 'Al-Fatihah');
    expect(recitation.startAyah, 1);
    expect(recitation.endAyah, 7);
    expect(recitation.current, 80);
    expect(recitation.total, 604);
    expect(recitation.percent, closeTo(80 / 604, 0.0001));
    expect(recitation.route, '/quran/page/1');
  });

  test('paused khatmah does not invent a daily target', () {
    final plan = KhatmahPlan(
      id: 'k1',
      title: KhatmahPlan.defaultTitle,
      status: KhatmahStatus.paused,
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: now,
      expectedEndDate: now.add(const Duration(days: 151)),
    );

    final recitation = mapper.map(
      isArabic: true,
      activeKhatmah: plan,
      lastRestorableLocation: '/quran/page/3',
      confirmedReadPages: 3,
    );

    expect(recitation, isNotNull);
    expect(recitation!.unit, ContinueRecitationUnit.pages);
    expect(recitation.route, '/quran/page/3');
    expect(recitation.current, 3);
    expect(recitation.total, 604);
  });
}
