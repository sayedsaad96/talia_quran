import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  group('KidsProgress.addPoints', () {
    test('adds the mastery stars supplied by the completed mission', () {
      const progress = KidsProgress.initial();

      final updated = progress.addPoints(10, stars: 3);

      expect(updated.totalPoints, 10);
      expect(updated.starsEarned, 3);
      expect(updated.ayahsCompleted, 1);
    });

    test('does not increment currentStreak (StreakService is SSOT)', () {
      const progress = KidsProgress(
        totalPoints: 0,
        currentLevel: 1,
        currentStreak: 7,
        starsEarned: 0,
        ayahsCompleted: 0,
        lastSessionAt: null,
      );

      final updated = progress.addPoints(14);

      expect(updated.currentStreak, 7);
      expect(updated.totalPoints, 14);
      expect(updated.ayahsCompleted, 1);
      expect(updated.lastSessionAt, isNotNull);
    });

    test('multiple addPoints on same day keep streak unchanged', () {
      var progress = const KidsProgress(
        totalPoints: 0,
        currentLevel: 1,
        currentStreak: 3,
        starsEarned: 0,
        ayahsCompleted: 0,
        lastSessionAt: null,
      );

      progress = progress.addPoints(10);
      progress = progress.addPoints(10);

      expect(progress.currentStreak, 3);
      expect(progress.ayahsCompleted, 2);
    });
  });

  group('KidsProgress level curve', () {
    test('the first level step is deliberately cheap', () {
      expect(KidsProgress.pointsForLevelStep(1), 50);
      expect(KidsProgress.pointsForLevelStep(2), 200);
      expect(KidsProgress.cumulativePointsForLevel(1), 0);
      expect(KidsProgress.cumulativePointsForLevel(2), 50);
      expect(KidsProgress.cumulativePointsForLevel(3), 250);
    });

    test('fifty points level a fresh child up immediately', () {
      var progress = const KidsProgress.initial();
      for (var i = 0; i < 5; i++) {
        progress = progress.addPoints(10);
      }

      expect(progress.totalPoints, 50);
      expect(progress.currentLevel, 2);
      expect(progress.pointsInCurrentLevel, 0);
      expect(progress.pointsForNextLevel, 200);
    });

    test('level thresholds match the cumulative curve', () {
      var progress = const KidsProgress.initial();
      for (var i = 0; i < 25; i++) {
        progress = progress.addPoints(10);
      }

      // 250 points = cumulative threshold for level 3.
      expect(progress.totalPoints, 250);
      expect(progress.currentLevel, 3);
    });
  });
}
