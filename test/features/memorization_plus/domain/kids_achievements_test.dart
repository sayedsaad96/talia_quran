import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_achievements.dart';

void main() {
  final now = DateTime.utc(2026, 10, 8, 9);

  KidsAchievement find(List<KidsAchievement> all, KidsAchievementId id) =>
      all.singleWhere((a) => a.id == id);

  test('nothing done unlocks nothing and shows zero progress', () {
    final all = KidsAchievementCatalog.evaluate(
      const KidsAchievementInputs(),
      now: now,
    );

    expect(all, hasLength(KidsAchievementCatalog.specs.length));
    expect(all.where((a) => a.isUnlocked), isEmpty);
    expect(find(all, KidsAchievementId.ayahs10).progress, 0);
  });

  test('meeting a target unlocks it now; progress is capped at the target', () {
    final all = KidsAchievementCatalog.evaluate(
      const KidsAchievementInputs(memorizedAyahs: 12, longestStreak: 3),
      now: now,
    );

    expect(find(all, KidsAchievementId.firstAyah).unlockedAt, now);
    expect(find(all, KidsAchievementId.ayahs10).isUnlocked, isTrue);
    expect(find(all, KidsAchievementId.ayahs10).current, 10);
    expect(find(all, KidsAchievementId.ayahs50).isUnlocked, isFalse);
    expect(find(all, KidsAchievementId.ayahs50).current, 12);
    expect(find(all, KidsAchievementId.ayahs50).progress, closeTo(0.24, 1e-9));
    expect(find(all, KidsAchievementId.streak3).isUnlocked, isTrue);
    expect(find(all, KidsAchievementId.streak7).isUnlocked, isFalse);
  });

  test('an unlock already stored keeps its date even when inputs drop', () {
    final earlier = DateTime.utc(2026, 9, 1);
    final all = KidsAchievementCatalog.evaluate(
      const KidsAchievementInputs(readPages: 2),
      now: now,
      unlocked: {KidsAchievementId.pages10.name: earlier},
    );

    final pages10 = find(all, KidsAchievementId.pages10);
    expect(pages10.isUnlocked, isTrue);
    expect(pages10.unlockedAt, earlier);
    expect(pages10.progress, 1);
  });

  test('every metric has a first milestone at 1', () {
    for (final metric in KidsAchievementMetric.values) {
      final targets = KidsAchievementCatalog.specs
          .where((s) => s.metric == metric)
          .map((s) => s.target);
      expect(targets.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(3));
    }
  });
}
