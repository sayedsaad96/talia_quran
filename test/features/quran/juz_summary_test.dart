import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';
import 'package:talia_quran/features/quran/domain/entities/juz_summary.dart';

/// Juz metadata is derived from the real bundled surah data (start pages),
/// so the surah ranges shown on Juz cards can never drift into hardcoded
/// display strings.
void main() {
  late final List<SurahModel> surahs;

  setUpAll(() {
    final list =
        jsonDecode(File('assets/data/surahs.json').readAsStringSync())
            as List<dynamic>;
    surahs = list
        .map((e) => SurahModel.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  group('JuzSummaries.fromSurahs', () {
    test('produces 30 summaries with standard start pages', () {
      final summaries = JuzSummaries.fromSurahs(surahs);

      expect(summaries, hasLength(30));
      expect(
        summaries.map((s) => s.startPage).toList(),
        JuzSummaries.startPages,
      );
      expect(summaries.first.juzNumber, 1);
      expect(summaries.last.endPage, 604);
    });

    test('every juz has a non-empty surah range from real data', () {
      final summaries = JuzSummaries.fromSurahs(surahs);

      for (final summary in summaries) {
        expect(
          summary.hasRange,
          isTrue,
          reason: 'juz ${summary.juzNumber} has no surahs',
        );
      }
    });

    test('juz 1 starts with Al-Fatihah and juz 30 ends with An-Nas', () {
      final summaries = JuzSummaries.fromSurahs(surahs);

      expect(summaries.first.firstSurah.id, 1);
      expect(summaries.last.lastSurah.id, 114);
    });

    test('surah ranges are contiguous across juz boundaries', () {
      final summaries = JuzSummaries.fromSurahs(surahs);

      for (var i = 0; i < summaries.length - 1; i++) {
        expect(
          summaries[i].endPage + 1,
          summaries[i + 1].startPage,
        );
      }
    });

    test('empty input yields empty output', () {
      expect(JuzSummaries.fromSurahs(const []), isEmpty);
    });
  });
}
