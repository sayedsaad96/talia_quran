import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

void main() {
  Achievement achievement(
    String id, {
    required int current,
    required int target,
    AchievementCategory category = AchievementCategory.reading,
  }) => Achievement(
    id: id,
    titleKey: id,
    descriptionKey: id,
    icon: '',
    isUnlocked: current >= target,
    category: category,
    currentValue: current,
    targetValue: target,
  );

  OverallProgress progressWith(List<Achievement> achievements) =>
      OverallProgress(
        memorizedAyahs: 0,
        totalAyahs: 6236,
        memorizedSurahs: 0,
        totalSurahs: 114,
        memorizedJuz: 0,
        totalJuz: 30,
        readAyahs: 0,
        readSurahs: 0,
        readJuz: 0,
        streakDays: 0,
        lastActiveDate: null,
        achievements: achievements,
        readPagesCount: 0,
        totalQuranPages: 604,
        learningAyahs: 0,
        reviewAyahs: 0,
      );

  group('OverallProgress.nextMilestone', () {
    test('picks the locked achievement with the most progress', () {
      final progress = progressWith([
        achievement('done', current: 1, target: 1),
        achievement('far', current: 1, target: 50),
        achievement('close', current: 8, target: 10),
      ]);

      expect(progress.nextMilestone?.id, 'close');
    });

    test('breaks ties with the smaller target', () {
      final progress = progressWith([
        achievement('big', current: 0, target: 604),
        achievement('small', current: 0, target: 3),
      ]);

      expect(progress.nextMilestone?.id, 'small');
    });

    test('is null when every achievement is unlocked', () {
      final progress = progressWith([
        achievement('a', current: 1, target: 1),
        achievement('b', current: 7, target: 7),
      ]);

      expect(progress.nextMilestone, isNull);
    });
  });

  test('Achievement.remaining never goes negative', () {
    expect(achievement('a', current: 3, target: 10).remaining, 7);
    expect(achievement('b', current: 12, target: 10).remaining, 0);
  });
}
