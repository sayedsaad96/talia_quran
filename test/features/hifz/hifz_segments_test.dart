import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/hifz/domain/hifz_unlock_rules.dart';

void main() {
  group('generateHifzSegments', () {
    List<String> rangesFor(int totalAyahs) {
      return generateHifzSegments(
        surahId: 1,
        totalAyahs: totalAyahs,
      ).map((segment) => '${segment.startAyah}-${segment.endAyah}').toList();
    }

    test('generates full-surah checkpoint for 5 ayahs', () {
      expect(rangesFor(5), equals(['1-5']));
    });

    test('generates full-surah checkpoint for 10 ayahs', () {
      expect(rangesFor(10), equals(['1-10']));
    });

    test('generates full-surah checkpoint for exactly 20 ayahs', () {
      expect(rangesFor(20), equals(['1-20']));
    });

    test('generates 10-ayah checkpoints for 21 ayahs', () {
      expect(rangesFor(21), equals(['1-10', '11-20', '21-21']));
    });

    test('generates final partial checkpoint for 23 ayahs', () {
      expect(rangesFor(23), equals(['1-10', '11-20', '21-23']));
    });

    test('generates exact 10-ayah checkpoints for 100 ayahs', () {
      expect(
        rangesFor(100),
        equals([
          '1-10',
          '11-20',
          '21-30',
          '31-40',
          '41-50',
          '51-60',
          '61-70',
          '71-80',
          '81-90',
          '91-100',
        ]),
      );
    });

    test('never lets the final checkpoint exceed 286 ayahs', () {
      final ranges = rangesFor(286);

      expect(ranges.first, '1-10');
      expect(ranges[ranges.length - 2], '271-280');
      expect(ranges.last, '281-286');
      expect(ranges, hasLength(29));
    });
  });
}
