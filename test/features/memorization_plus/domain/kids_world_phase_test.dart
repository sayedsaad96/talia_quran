import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_world_phase.dart';

void main() {
  group('kidsWorldPhaseAt', () {
    final fajr = DateTime(2026, 10, 2, 4, 30);
    final maghrib = DateTime(2026, 10, 2, 17, 40);

    test('returns night before fajr', () {
      final now = DateTime(2026, 10, 2, 4, 29);
      expect(
        kidsWorldPhaseAt(now, fajr: fajr, maghrib: maghrib),
        KidsWorldPhase.night,
      );
    });

    test('returns day at fajr', () {
      final now = DateTime(2026, 10, 2, 4, 30);
      expect(
        kidsWorldPhaseAt(now, fajr: fajr, maghrib: maghrib),
        KidsWorldPhase.day,
      );
    });

    test('returns day before maghrib', () {
      final now = DateTime(2026, 10, 2, 17, 39);
      expect(
        kidsWorldPhaseAt(now, fajr: fajr, maghrib: maghrib),
        KidsWorldPhase.day,
      );
    });

    test('returns night at maghrib', () {
      final now = DateTime(2026, 10, 2, 17, 40);
      expect(
        kidsWorldPhaseAt(now, fajr: fajr, maghrib: maghrib),
        KidsWorldPhase.night,
      );
    });

    test('returns night after maghrib', () {
      final now = DateTime(2026, 10, 2, 23, 59);
      expect(
        kidsWorldPhaseAt(now, fajr: fajr, maghrib: maghrib),
        KidsWorldPhase.night,
      );
    });

    group('fallback (both null)', () {
      test('returns night before 06:00', () {
        final now = DateTime(2026, 10, 2, 5, 59);
        expect(kidsWorldPhaseAt(now), KidsWorldPhase.night);
      });

      test('returns day at 06:00', () {
        final now = DateTime(2026, 10, 2, 6, 0);
        expect(kidsWorldPhaseAt(now), KidsWorldPhase.day);
      });

      test('returns day before 18:00', () {
        final now = DateTime(2026, 10, 2, 17, 59);
        expect(kidsWorldPhaseAt(now), KidsWorldPhase.day);
      });

      test('returns night at 18:00', () {
        final now = DateTime(2026, 10, 2, 18, 0);
        expect(kidsWorldPhaseAt(now), KidsWorldPhase.night);
      });
    });

    test('uses fallback when only fajr supplied', () {
      final now = DateTime(2026, 10, 2, 5, 59);
      expect(kidsWorldPhaseAt(now, fajr: fajr), KidsWorldPhase.night);
    });

    test('uses fallback when only maghrib supplied', () {
      final now = DateTime(2026, 10, 2, 5, 59);
      expect(kidsWorldPhaseAt(now, maghrib: maghrib), KidsWorldPhase.night);
    });
  });

  group('kidsWorldNextBoundary', () {
    final fajr = DateTime(2026, 10, 2, 4, 30);
    final maghrib = DateTime(2026, 10, 2, 17, 40);

    test('returns today maghrib from day time', () {
      final now = DateTime(2026, 10, 2, 10, 0);
      final nextBoundary = kidsWorldNextBoundary(
        now,
        fajr: fajr,
        maghrib: maghrib,
      );
      expect(nextBoundary, maghrib);
    });

    test('returns tomorrow fajr from night time after maghrib', () {
      final now = DateTime(2026, 10, 2, 20, 0);
      final nextBoundary = kidsWorldNextBoundary(
        now,
        fajr: fajr,
        maghrib: maghrib,
      );
      expect(nextBoundary, fajr.add(const Duration(days: 1)));
    });

    test('returns today fajr from night time before fajr', () {
      final now = DateTime(2026, 10, 2, 2, 0);
      final nextBoundary = kidsWorldNextBoundary(
        now,
        fajr: fajr,
        maghrib: maghrib,
      );
      expect(nextBoundary, fajr);
    });

    group('fallback', () {
      test('returns today 18:00 from day time', () {
        final now = DateTime(2026, 10, 2, 12, 0);
        final nextBoundary = kidsWorldNextBoundary(now);
        expect(nextBoundary, DateTime(2026, 10, 2, 18, 0));
      });

      test('returns next day 06:00 from night time', () {
        final now = DateTime(2026, 10, 2, 19, 0);
        final nextBoundary = kidsWorldNextBoundary(now);
        expect(nextBoundary, DateTime(2026, 10, 3, 6, 0));
      });

      test('returns same-day 06:00 from after midnight (02:00)', () {
        final nextBoundary = kidsWorldNextBoundary(DateTime(2026, 10, 2, 2, 0));
        expect(nextBoundary, DateTime(2026, 10, 2, 6, 0));
      });

      test('returns 18:00 same day at exactly 06:00', () {
        final nextBoundary = kidsWorldNextBoundary(DateTime(2026, 10, 2, 6, 0));
        expect(nextBoundary, DateTime(2026, 10, 2, 18, 0));
      });

      test('returns next day 06:00 at exactly 18:00', () {
        final nextBoundary = kidsWorldNextBoundary(
          DateTime(2026, 10, 2, 18, 0),
        );
        expect(nextBoundary, DateTime(2026, 10, 3, 6, 0));
      });

      test('rolls over month end at 18:00', () {
        final nextBoundary = kidsWorldNextBoundary(
          DateTime(2026, 10, 31, 18, 0),
        );
        expect(nextBoundary, DateTime(2026, 11, 1, 6, 0));
      });
    });

    test('at exactly fajr returns maghrib', () {
      expect(
        kidsWorldNextBoundary(fajr, fajr: fajr, maghrib: maghrib),
        maghrib,
      );
    });

    test('at exactly maghrib returns fajr + 1 day', () {
      expect(
        kidsWorldNextBoundary(maghrib, fajr: fajr, maghrib: maghrib),
        fajr.add(const Duration(days: 1)),
      );
    });

    test('only fajr supplied uses fallback', () {
      final now = DateTime(2026, 10, 2, 12, 0);
      expect(kidsWorldNextBoundary(now, fajr: fajr), DateTime(2026, 10, 2, 18));
    });

    test('only maghrib supplied uses fallback', () {
      final now = DateTime(2026, 10, 2, 2, 0);
      expect(
        kidsWorldNextBoundary(now, maghrib: maghrib),
        DateTime(2026, 10, 2, 6),
      );
    });
  });
}
