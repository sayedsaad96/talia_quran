import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/utils/mushaf_hizb_helper.dart';

void main() {
  group('juz lookup', () {
    test('last juz pages report juz 30', () {
      expect(MushafHizbHelper.getJuz(581), 29);
      expect(MushafHizbHelper.getJuz(582), 30);
      expect(MushafHizbHelper.getJuz(604), 30);
    });

    test('first juz boundaries', () {
      expect(MushafHizbHelper.getJuz(1), 1);
      expect(MushafHizbHelper.getJuz(21), 1);
      expect(MushafHizbHelper.getJuz(22), 2);
    });

    test('juzPageRange covers the mushaf without gaps', () {
      expect(MushafHizbHelper.juzPageRange(1), (start: 1, end: 21));
      expect(MushafHizbHelper.juzPageRange(30), (start: 582, end: 604));
      var expected = 1;
      for (var juz = 1; juz <= 30; juz++) {
        final range = MushafHizbHelper.juzPageRange(juz);
        expect(range.start, expected);
        expected = range.end + 1;
      }
      expect(expected, 605);
    });
  });
}
