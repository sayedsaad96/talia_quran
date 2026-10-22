import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/strength_band.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';

final _now = DateTime.utc(2026, 10, 16, 12);

AyahReviewRecord _rec({
  required int level,
  int reviews = 3,
  bool due = false,
}) => AyahReviewRecord(
  surahId: 1,
  ayahNumber: 1,
  strengthLevel: level,
  intervalDays: 1,
  lastReviewedAt: _now.subtract(const Duration(days: 1)),
  nextReviewDate: due
      ? _now.subtract(const Duration(hours: 1))
      : _now.add(const Duration(days: 3)),
  totalReviews: reviews,
  lastRating: PerformanceRating.average,
);

void main() {
  test('band boundaries: null, 0 reviews, due wins over solid, 2→weak, '
      '3→building, 5→building, 6→solid', () {
    expect(strengthBandFor(null, _now), StrengthBand.none);
    expect(
      strengthBandFor(_rec(level: 4, reviews: 0), _now),
      StrengthBand.none,
    );
    expect(strengthBandFor(_rec(level: 7, due: true), _now), StrengthBand.due);
    expect(strengthBandFor(_rec(level: 0), _now), StrengthBand.weak);
    expect(strengthBandFor(_rec(level: 1), _now), StrengthBand.weak);
    expect(strengthBandFor(_rec(level: 2), _now), StrengthBand.weak);
    expect(strengthBandFor(_rec(level: 3), _now), StrengthBand.building);
    expect(strengthBandFor(_rec(level: 5), _now), StrengthBand.building);
    expect(strengthBandFor(_rec(level: 6), _now), StrengthBand.solid);
    expect(strengthBandFor(_rec(level: 9), _now), StrengthBand.solid);
  });
}
