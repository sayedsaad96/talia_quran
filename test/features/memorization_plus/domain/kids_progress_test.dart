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
}
