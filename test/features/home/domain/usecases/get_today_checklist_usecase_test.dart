import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/home/domain/entities/today_checklist.dart';
import 'package:talia_quran/features/home/domain/usecases/get_today_checklist_usecase.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

void main() {
  TodayChecklist checklistWith({
    required OverallProgress progress,
    bool memorizedToday = false,
    bool reviewedToday = false,
  }) {
    return const GetTodayChecklistUsecase().call(
      TodayChecklistParams(
        progress: progress,
        wirdPage: 1,
        wirdComplete: false,
        readingRoute: '/quran/page/1',
        memorizeRoute: '/memorization',
        reviewRoute: '/memorization',
        azkarRoute: '/azkar/morning',
        azkarComplete: false,
        khatmah: null,
        dailyPlan: null,
        azkarCategory: AzkarCategory.morning,
        memorizedToday: memorizedToday,
        reviewedToday: reviewedToday,
      ),
    );
  }

  bool isComplete(TodayChecklist checklist, TodayTaskKind kind) =>
      checklist.tasks.singleWhere((task) => task.kind == kind).isComplete;

  test('marks memorization complete once a session is logged today', () {
    const progress = OverallProgress(
      memorizedAyahs: 10,
      totalAyahs: 6236,
      memorizedSurahs: 1,
      totalSurahs: 114,
      memorizedJuz: 0,
      totalJuz: 30,
      readAyahs: 0,
      readSurahs: 0,
      readJuz: 0,
      streakDays: 0,
      lastActiveDate: null,
      achievements: [],
      readPagesCount: 0,
      totalQuranPages: 604,
      learningAyahs: 0,
      reviewAyahs: 0,
    );

    expect(
      isComplete(
        checklistWith(progress: progress, memorizedToday: true),
        TodayTaskKind.memorize,
      ),
      isTrue,
    );
  });

  test('marks review complete from a logged session while more remain due', () {
    const progress = OverallProgress(
      memorizedAyahs: 10,
      totalAyahs: 6236,
      memorizedSurahs: 1,
      totalSurahs: 114,
      memorizedJuz: 0,
      totalJuz: 30,
      readAyahs: 0,
      readSurahs: 0,
      readJuz: 0,
      streakDays: 0,
      lastActiveDate: null,
      achievements: [],
      readPagesCount: 0,
      totalQuranPages: 604,
      learningAyahs: 0,
      reviewAyahs: 4,
    );

    expect(
      isComplete(checklistWith(progress: progress), TodayTaskKind.review),
      isFalse,
    );
    expect(
      isComplete(
        checklistWith(progress: progress, reviewedToday: true),
        TodayTaskKind.review,
      ),
      isTrue,
    );
  });

  test('does not treat historical memorization as work completed today', () {
    const progress = OverallProgress(
      memorizedAyahs: 10,
      totalAyahs: 6236,
      memorizedSurahs: 1,
      totalSurahs: 114,
      memorizedJuz: 0,
      totalJuz: 30,
      readAyahs: 0,
      readSurahs: 0,
      readJuz: 0,
      streakDays: 0,
      lastActiveDate: null,
      achievements: [],
      readPagesCount: 0,
      totalQuranPages: 604,
      learningAyahs: 0,
      reviewAyahs: 0,
    );
    final checklist = const GetTodayChecklistUsecase().call(
      const TodayChecklistParams(
        progress: progress,
        wirdPage: 1,
        wirdComplete: false,
        readingRoute: '/quran/page/1',
        memorizeRoute: '/memorization',
        reviewRoute: '/memorization',
        azkarRoute: '/azkar/morning',
        azkarComplete: false,
        khatmah: null,
        dailyPlan: null,
        azkarCategory: AzkarCategory.morning,
      ),
    );

    final memorize = checklist.tasks.singleWhere(
      (task) => task.kind == TodayTaskKind.memorize,
    );
    expect(memorize.isComplete, isFalse);
    final review = checklist.tasks.singleWhere(
      (task) => task.kind == TodayTaskKind.review,
    );
    expect(review.isComplete, isFalse);
  });
}
