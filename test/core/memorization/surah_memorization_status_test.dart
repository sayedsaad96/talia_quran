import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/surah_memorization_status.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

/// N17: the surah list gave no hint of what the learner has memorized.
void main() {
  AyahReviewRecord record(
    int surah,
    int ayah, {
    int strength = 3,
    int reviews = 2,
    ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.v2Session,
  }) {
    final at = DateTime.utc(2026, 9, 1);
    return AyahReviewRecord(
      surahId: surah,
      ayahNumber: ayah,
      strengthLevel: strength,
      intervalDays: 3,
      lastReviewedAt: at,
      nextReviewDate: at.add(const Duration(days: 3)),
      totalReviews: reviews,
      lastRating: PerformanceRating.excellent,
      createdByMode: mode,
    );
  }

  const ayahCounts = {112: 4, 113: 5, 114: 6};

  test('a surah with every ayah memorized is memorized', () {
    final statuses = SurahMemorizationStatus.fromRecords([
      for (var a = 1; a <= 4; a++) record(112, a, strength: 6),
    ], ayahCounts: ayahCounts);

    expect(statuses[112], SurahMemorizationStatus.memorized);
  });

  test('a surah with reviewed ayahs but gaps is in progress', () {
    final statuses = SurahMemorizationStatus.fromRecords([
      record(113, 1, strength: 6),
      record(113, 2),
    ], ayahCounts: ayahCounts);

    expect(statuses[113], SurahMemorizationStatus.inProgress);
  });

  test('never-reviewed and non-adult records do not count', () {
    final statuses = SurahMemorizationStatus.fromRecords([
      record(114, 1, reviews: 0),
      record(112, 1, mode: ReviewRecordCreatedByMode.kidsMode),
    ], ayahCounts: ayahCounts);

    expect(statuses, isEmpty);
  });
}
