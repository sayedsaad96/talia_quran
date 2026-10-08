import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_achievements.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_progress_talia_cue.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_companion.dart';

void main() {
  final now = DateTime.utc(2026, 10, 8, 12);

  List<KidsAchievement> evaluate(
    KidsAchievementInputs inputs, {
    Map<String, DateTime> unlocked = const {},
  }) => KidsAchievementCatalog.evaluate(
    inputs,
    now: DateTime.utc(2026, 9, 1),
    unlocked: unlocked,
  );

  test('nothing yet: Talia encourages the first step', () {
    final cue = kidsProgressTaliaCue(
      evaluate(const KidsAchievementInputs()),
      now: now,
    );

    expect(cue.kind, KidsProgressCueKind.start);
    expect(cue.pose, KidsTaliaPose.encourage);
  });

  test('a milestone reached in the last day is celebrated', () {
    final all = KidsAchievementCatalog.evaluate(
      const KidsAchievementInputs(memorizedAyahs: 10),
      now: now.subtract(const Duration(hours: 3)),
      unlocked: {'firstAyah': DateTime.utc(2026, 9, 1)},
    );

    final cue = kidsProgressTaliaCue(all, now: now);

    expect(cue.kind, KidsProgressCueKind.newAchievement);
    expect(cue.pose, KidsTaliaPose.celebrate);
    expect(cue.achievement!.id, KidsAchievementId.ayahs10);
  });

  test('milestones reached together: the bigger one is celebrated', () {
    final all = KidsAchievementCatalog.evaluate(
      const KidsAchievementInputs(memorizedAyahs: 12),
      now: now.subtract(const Duration(hours: 1)),
    );

    final cue = kidsProgressTaliaCue(all, now: now);

    expect(cue.achievement!.id, KidsAchievementId.ayahs10);
  });

  test('otherwise Talia points at the closest milestone', () {
    final cue = kidsProgressTaliaCue(
      // 8/10 ayahs (0.8) beats 2/3 days in a row (0.67).
      evaluate(
        const KidsAchievementInputs(memorizedAyahs: 8, longestStreak: 2),
      ),
      now: now,
    );

    expect(cue.kind, KidsProgressCueKind.next);
    expect(cue.pose, KidsTaliaPose.pointRight);
    expect(cue.achievement!.id, KidsAchievementId.ayahs10);
  });

  test('every milestone reached is a celebration', () {
    final cue = kidsProgressTaliaCue(
      evaluate(
        const KidsAchievementInputs(
          memorizedAyahs: 100,
          memorizedSurahs: 10,
          readPages: 30,
          longestStreak: 30,
          stars: 50,
        ),
      ),
      now: now,
    );

    expect(cue.kind, KidsProgressCueKind.allDone);
    expect(cue.pose, KidsTaliaPose.celebrate);
  });
}
