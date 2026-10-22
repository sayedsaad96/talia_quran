import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/strength_band.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/quran/presentation/services/strength_overlay_source.dart';

final _now = DateTime.utc(2026, 10, 16, 12);

AyahReviewRecord _rec(int surah, int ayah, int level, {bool due = false}) =>
    AyahReviewRecord(
      surahId: surah,
      ayahNumber: ayah,
      strengthLevel: level,
      intervalDays: 1,
      lastReviewedAt: _now.subtract(const Duration(days: 1)),
      nextReviewDate: due
          ? _now.subtract(const Duration(hours: 1))
          : _now.add(const Duration(days: 3)),
      totalReviews: 2,
      lastRating: PerformanceRating.average,
    );

void main() {
  late int calls;
  late StrengthOverlaySource source;

  setUp(() {
    calls = 0;
    source = StrengthOverlaySource(
      pageRanges: (page) {
        calls++;
        return page == 2
            ? [(surah: 2, start: 1, end: 4), (surah: 3, start: 1, end: 2)]
            : [];
      },
    );
  });

  test('bandsForPage covers only ayahs in the page ranges and omits none', () {
    source.setRecords([
      _rec(2, 1, 1),
      _rec(2, 3, 6),
      _rec(3, 2, 4, due: true),
      _rec(2, 9, 6), // outside the page range
      _rec(5, 1, 6), // other surah
    ]);
    final bands = source.bandsForPage(2, _now);
    expect(bands, {
      (surah: 2, ayah: 1): StrengthBand.weak,
      (surah: 2, ayah: 3): StrengthBand.solid,
      (surah: 3, ayah: 2): StrengthBand.due,
    });
    expect(source.bandsForPage(7, _now), isEmpty);
  });

  test('setRecords clears the page cache; clear() empties results', () {
    source.setRecords([_rec(2, 1, 1)]);
    source.bandsForPage(2, _now);
    source.bandsForPage(2, _now);
    expect(calls, 1);
    source.setRecords([_rec(2, 2, 7)]);
    expect(source.bandsForPage(2, _now), {
      (surah: 2, ayah: 2): StrengthBand.solid,
    });
    expect(calls, 2);
    source.clear();
    expect(source.bandsForPage(2, _now), isEmpty);
  });
}
