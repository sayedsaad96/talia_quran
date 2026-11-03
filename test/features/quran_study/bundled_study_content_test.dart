import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran_study/data/datasources/approved_study_bundle_source.dart';

void main() {
  test(
    'shipped study bundles have valid hashes and complete verse coverage',
    () {
      final surahs =
          jsonDecode(File('assets/data/surahs.json').readAsStringSync())
              as List;
      final counts = <int, int>{
        for (final surah in surahs)
          surah['id'] as int: surah['ayahCount'] as int,
      };
      final manifest =
          jsonDecode(
                File(
                  'assets/data/quran_study/study_manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      for (final item in {
        'tafsir': 'tafsir_ar.json',
        'meaningTranslation': 'translation_en.json',
      }.entries) {
        final result = validateStudyBundle(
          bytes: File(
            'assets/data/quran_study/${item.value}',
          ).readAsBytesSync(),
          manifestEntry: (manifest[item.key] as Map).cast<String, Object?>(),
          canonicalAyahCounts: counts,
        );
        expect(result.errors, isEmpty, reason: item.key);
        expect(result.blocks, hasLength(6236));
      }
    },
  );
}
