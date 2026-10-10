import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_house_review_policy.dart';

void main() {
  test('no house range has no review work', () {
    expect(KidsHouseReviewPolicy.pendingAyahs(const [], 1, const []), isEmpty);
  });
  final first = DateTime.utc(2026, 1, 1);
  KidsSessionLog log(
    int ayah,
    DateTime at, {
    bool review = false,
    PerformanceRating rating = PerformanceRating.excellent,
    String id = 'id',
  }) => KidsSessionLog(
    id: review ? KidsHouseReviewPolicy.proofId(1, ayah, id) : id,
    surahId: 1,
    ayahNumber: ayah,
    repeatsCompleted: 1,
    pointsEarned: 1,
    completedAt: at,
    missionType: review
        ? KidsMissionType.linkedReview
        : KidsMissionType.newMemorization,
    masteryRating: rating,
  );

  test(
    'requires a verified later review for every ayah after house completion',
    () {
      final logs = [
        log(1, first),
        log(2, first.add(const Duration(minutes: 1))),
        log(1, first.add(const Duration(minutes: 2)), review: true),
      ];
      expect(KidsHouseReviewPolicy.pendingAyahs(logs, 1, [1, 2]), [2]);
    },
  );
  test('review before final first pass does not count', () {
    final logs = [
      log(1, first),
      log(1, first.add(const Duration(seconds: 1)), review: true),
      log(2, first.add(const Duration(seconds: 2))),
    ];
    expect(KidsHouseReviewPolicy.pendingAyahs(logs, 1, [1, 2]), [1, 2]);
  });
  test('weak or arbitrary linked review cannot prove the house review', () {
    final logs = [
      log(1, first),
      log(2, first),
      log(
        1,
        first.add(const Duration(minutes: 1)),
        review: true,
        rating: PerformanceRating.weak,
      ),
      KidsSessionLog(
        id: 'arbitrary',
        surahId: 1,
        ayahNumber: 2,
        repeatsCompleted: 1,
        pointsEarned: 1,
        completedAt: first.add(const Duration(minutes: 1)),
        missionType: KidsMissionType.linkedReview,
      ),
    ];
    expect(KidsHouseReviewPolicy.pendingAyahs(logs, 1, [1, 2]), [1, 2]);
  });
}
