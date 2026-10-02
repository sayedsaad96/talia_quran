import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_adventure_regions.dart';

KidsSessionLog _log(
  int surahId,
  int ayah, {
  KidsMissionType type = KidsMissionType.newMemorization,
  int points = 10,
  List<int> ayahNumbers = const [],
  String? id,
}) => KidsSessionLog(
  id: id ?? 's$surahId-$ayah-${type.name}',
  surahId: surahId,
  ayahNumber: ayah,
  repeatsCompleted: 3,
  pointsEarned: points,
  completedAt: DateTime(2026, 10, 2),
  missionType: type,
  ayahNumbers: ayahNumbers,
);

void main() {
  const counts = {114: 6, 1: 7};

  test(
    'regions cover KidsJourneyPath.surahIds exactly once, in path order',
    () {
      final flat = [for (final r in kKidsAdventureRegions) ...r.surahIds];
      expect(flat, KidsJourneyPath.surahIds);
    },
  );

  test('a surah is memorized when every ayah has a canonical log', () {
    final all = [for (var a = 1; a <= 6; a++) _log(114, a)];
    expect(kidsMemorizedSurahIds(all, counts), {114});
    expect(kidsMemorizedSurahIds(all.take(5).toList(), counts), isEmpty);
  });

  test('ayahNumbers and ayahNumber are unioned', () {
    final logs = [
      _log(114, 1, ayahNumbers: const [1, 2, 3]),
      _log(114, 4, ayahNumbers: const [4, 5, 6]),
    ];
    expect(kidsMemorizedSurahIds(logs, counts), {114});
  });

  test('review-only logs do not count', () {
    final logs = [
      for (var a = 1; a <= 6; a++)
        _log(114, a, type: KidsMissionType.dueReview),
    ];
    expect(kidsMemorizedSurahIds(logs, counts), isEmpty);
  });

  test('duplicate logs from two devices count once', () {
    final logs = [
      for (var a = 1; a <= 6; a++) ...[
        _log(114, a, id: 'a$a'),
        _log(114, a, id: 'b$a'),
      ],
    ];
    expect(kidsMemorizedSurahIds(logs, counts), {114});
  });

  test('surahs missing from the ayah-count map are never memorized', () {
    final logs = [for (var a = 1; a <= 6; a++) _log(113, a)];
    expect(kidsMemorizedSurahIds(logs, counts), isEmpty);
  });

  test('kidsRegionProgress reports per-region counts', () {
    final progress = kidsRegionProgress({1, 114});
    expect(progress, hasLength(5));
    expect(progress[0].region.id, KidsRegionId.beginning);
    expect(progress[0].isComplete, isTrue);
    expect(progress[1].region.id, KidsRegionId.palmOasis);
    expect(progress[1].memorized, 1);
    expect(progress[1].total, 6);
    expect(progress[1].isComplete, isFalse);
  });

  test('kidsRegionOf resolves a surah and throws off the path', () {
    expect(kidsRegionOf(112).id, KidsRegionId.palmOasis);
    expect(() => kidsRegionOf(2), throwsStateError);
  });
}
