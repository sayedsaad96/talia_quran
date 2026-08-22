import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/data/services/quran_warmup_service.dart';

void main() {
  group('QuranWarmupService.parsePageFromLocation', () {
    test('parses direct page locations', () {
      expect(QuranWarmupService.parsePageFromLocation('/quran/page/1'), 1);
      expect(QuranWarmupService.parsePageFromLocation('/quran/page/42'), 42);
      expect(QuranWarmupService.parsePageFromLocation('/quran/page/604'), 604);
    });

    test('maps surah locations to their first Mushaf page', () {
      expect(QuranWarmupService.parsePageFromLocation('/quran/surah/1'), 1);
      expect(QuranWarmupService.parsePageFromLocation('/quran/surah/2'), 2);
      expect(QuranWarmupService.parsePageFromLocation('/quran/surah/114'), 604);
    });

    test('returns null for non-Quran or invalid locations', () {
      expect(QuranWarmupService.parsePageFromLocation(null), isNull);
      expect(QuranWarmupService.parsePageFromLocation('/home'), isNull);
      expect(QuranWarmupService.parsePageFromLocation('/quran'), isNull);
      expect(QuranWarmupService.parsePageFromLocation('/quran/page/0'), isNull);
      expect(
        QuranWarmupService.parsePageFromLocation('/quran/page/605'),
        isNull,
      );
      expect(
        QuranWarmupService.parsePageFromLocation('/quran/page/abc'),
        isNull,
      );
      expect(
        QuranWarmupService.parsePageFromLocation('/quran/surah/0'),
        isNull,
      );
      expect(
        QuranWarmupService.parsePageFromLocation('/quran/surah/115'),
        isNull,
      );
      expect(
        QuranWarmupService.parsePageFromLocation('/memorization-plus/journey/2'),
        isNull,
      );
    });
  });

  group('QuranWarmupService.buildPriorityPages', () {
    test('always includes the Mushaf opening pages', () {
      final pages = QuranWarmupService.buildPriorityPages(null);

      expect(pages.first, 1);
      expect(pages, contains(2));
    });

    test('includes a window around the last-read page', () {
      final pages = QuranWarmupService.buildPriorityPages('/quran/page/100');

      expect(pages, containsAll([97, 98, 99, 100, 101, 102, 103]));
    });

    test('clamps the window to the valid Mushaf range', () {
      final firstPages = QuranWarmupService.buildPriorityPages('/quran/page/1');
      final lastPages = QuranWarmupService.buildPriorityPages(
        '/quran/page/604',
      );

      expect(firstPages.first, 1);
      expect(lastPages.last, 604);
      expect(
        lastPages.every((page) => page >= 1 && page <= 604),
        isTrue,
      );
    });
  });
}
