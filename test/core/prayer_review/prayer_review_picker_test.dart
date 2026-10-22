import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_picker.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  final now = DateTime.utc(2026, 10, 20, 12);

  PrayerReviewPassage? pick({
    required List<AyahReviewRecord> records,
    required List<Ayah> canonical,
    int max = 3,
  }) {
    return PrayerReviewPicker.pick(
      records: records,
      canonicalAyahs: canonical,
      now: now,
      maxAyahs: max,
    );
  }

  AyahReviewRecord record({
    int surah = 1,
    int ayahNumber = 1,
    int strength = 6,
    double stability = 10,
    DateTime? due,
    DateTime? reviewed,
    ReviewRecordCreatedByMode source = ReviewRecordCreatedByMode.v2Session,
  }) {
    return AyahReviewRecord(
      surahId: surah,
      ayahNumber: ayahNumber,
      strengthLevel: strength,
      intervalDays: 7,
      lastReviewedAt: reviewed ?? now.subtract(const Duration(days: 10)),
      nextReviewDate: due ?? now.subtract(const Duration(days: 1)),
      totalReviews: 1,
      lastRating: PerformanceRating.average,
      stability: stability,
      createdByMode: source,
    );
  }

  Ayah ayah(int surah, int number, {int page = 1}) {
    return Ayah(
      number: surah * 1000 + number,
      surahId: surah,
      text: '',
      numberInSurah: number,
      page: page,
    );
  }

  group('PrayerReviewPicker', () {
    test('returns no passage for empty records or an unsupported length', () {
      expect(
        PrayerReviewPicker.pick(
          records: const [],
          canonicalAyahs: const [],
          now: now,
          maxAyahs: 3,
        ),
        isNull,
      );
      expect(
        pick(records: [record()], canonical: [ayah(1, 1)], max: 4),
        isNull,
      );
    });

    test('prioritizes the earliest due memorized adult ayah', () {
      final result = pick(
        records: [
          record(ayahNumber: 1, due: now.subtract(const Duration(days: 1))),
          record(
            ayahNumber: 2,
            due: now.subtract(const Duration(days: 3)),
            stability: 1000,
          ),
        ],
        canonical: [ayah(1, 1), ayah(1, 2)],
      );

      expect(
        result,
        const PrayerReviewPassage(surahId: 1, startAyah: 2, endAyah: 2),
      );
    });

    test('uses weakest D1 retrievability after an equal due date', () {
      final result = pick(
        records: [
          record(ayahNumber: 1, stability: 100),
          record(ayahNumber: 2, stability: 1),
        ],
        canonical: [ayah(1, 1), ayah(1, 2)],
      );

      expect(
        result,
        const PrayerReviewPassage(surahId: 1, startAyah: 2, endAyah: 2),
      );
    });

    test(
      'uses due date then oldest review for legacy records without forecast',
      () {
        final result = pick(
          records: [
            record(
              ayahNumber: 1,
              stability: 0,
              due: now.subtract(const Duration(days: 1)),
              reviewed: now.subtract(const Duration(days: 9)),
            ),
            record(
              ayahNumber: 2,
              stability: 0,
              due: now.subtract(const Duration(days: 2)),
              reviewed: now.subtract(const Duration(days: 99)),
            ),
          ],
          canonical: [ayah(1, 1), ayah(1, 2)],
        );

        expect(
          result,
          const PrayerReviewPassage(surahId: 1, startAyah: 2, endAyah: 2),
        );
      },
    );

    test('uses numeric IDs then extends contiguous equal-priority records', () {
      final result = pick(
        records: [
          record(
            ayahNumber: 2,
            stability: 0,
            reviewed: now.subtract(const Duration(days: 8)),
          ),
          record(
            ayahNumber: 1,
            stability: 0,
            reviewed: now.subtract(const Duration(days: 8)),
          ),
          record(
            ayahNumber: 3,
            stability: 0,
            reviewed: now.subtract(const Duration(days: 8)),
          ),
        ],
        canonical: [ayah(1, 1), ayah(1, 2), ayah(1, 3)],
      );

      expect(result, isNotNull);
      expect(result!.surahId, 1);
      expect(result.startAyah, 1);
      expect(result.endAyah, 3);
    });

    test('uses the oldest review before numeric IDs when due dates match', () {
      final result = pick(
        records: [
          record(
            ayahNumber: 1,
            stability: 0,
            reviewed: now.subtract(const Duration(days: 4)),
          ),
          record(
            ayahNumber: 2,
            stability: 0,
            reviewed: now.subtract(const Duration(days: 8)),
          ),
        ],
        canonical: [ayah(1, 1), ayah(1, 2)],
      );

      expect(
        result,
        const PrayerReviewPassage(surahId: 1, startAyah: 2, endAyah: 2),
      );
    });

    test('selects only memorized adult-compatible records', () {
      final result = pick(
        records: [
          record(ayahNumber: 1, strength: 5),
          record(ayahNumber: 2, source: ReviewRecordCreatedByMode.kidsMode),
          record(ayahNumber: 3),
        ],
        canonical: [ayah(1, 1), ayah(1, 2), ayah(1, 3)],
      );

      expect(
        result,
        const PrayerReviewPassage(surahId: 1, startAyah: 3, endAyah: 3),
      );
    });

    test(
      'extends only contiguous same-surah eligible ayahs and permits page crossing',
      () {
        final result = pick(
          records: [
            record(ayahNumber: 1),
            record(ayahNumber: 2),
            record(ayahNumber: 4),
          ],
          canonical: [
            ayah(1, 1, page: 1),
            ayah(1, 2, page: 2),
            ayah(1, 4, page: 2),
          ],
        );

        expect(
          result,
          const PrayerReviewPassage(surahId: 1, startAyah: 1, endAyah: 2),
        );
      },
    );

    test('stops at a surah boundary even when the next ayah is eligible', () {
      final result = pick(
        records: [record(ayahNumber: 7), record(surah: 2, ayahNumber: 1)],
        canonical: [ayah(1, 7), ayah(2, 1)],
      );

      expect(
        result,
        const PrayerReviewPassage(surahId: 1, startAyah: 7, endAyah: 7),
      );
    });

    test('supports the allowed maximum of fifteen', () {
      final records = [
        for (var number = 1; number <= 16; number++)
          record(surah: 2, ayahNumber: number),
      ];
      final canonical = [
        for (var number = 1; number <= 16; number++) ayah(2, number),
        ayah(3, 1),
      ];

      final result = pick(records: records, canonical: canonical, max: 15);

      expect(
        result,
        const PrayerReviewPassage(surahId: 2, startAyah: 1, endAyah: 15),
      );
    });

    test(
      'omits an already assessed exact passage and considers the next start',
      () {
        final result = PrayerReviewPicker.pick(
          records: [record(ayahNumber: 1), record(ayahNumber: 3)],
          canonicalAyahs: [ayah(1, 1), ayah(1, 3)],
          now: now,
          maxAyahs: 3,
          excludedPassages: {
            const PrayerReviewPassage(surahId: 1, startAyah: 1, endAyah: 1),
          },
        );

        expect(
          result,
          const PrayerReviewPassage(surahId: 1, startAyah: 3, endAyah: 3),
        );
      },
    );

    test(
      'fails closed for duplicate IDs, invalid bounds, or missing canonical metadata',
      () {
        final duplicate = record(ayahNumber: 1);
        expect(
          pick(records: [duplicate, duplicate], canonical: [ayah(1, 1)]),
          isNull,
        );
        expect(
          pick(records: [record(ayahNumber: 8)], canonical: [ayah(1, 8)]),
          isNull,
        );
        expect(pick(records: [record()], canonical: const []), isNull);
        expect(
          PrayerReviewPicker.pick(
            records: [record()],
            canonicalAyahs: [ayah(1, 1), ayah(1, 1)],
            now: now,
            maxAyahs: 3,
          ),
          isNull,
        );
      },
    );
  });
}
