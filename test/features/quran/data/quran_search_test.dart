import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';

void main() {
  // The real bundled corpus, read from disk.
  QuranLocalDatasourceImpl datasource() =>
      QuranLocalDatasourceImpl(loadAsset: (path) => File(path).readAsString());

  test('plain-script queries find Uthmani ayahs', () async {
    final source = datasource();

    final results = await source.searchAyahs('الرحمن الرحيم');

    final keys = results.map((a) => '${a.surahId}:${a.numberInSurah}');
    expect(keys, containsAll(['1:1', '1:3']));
  });

  test('later searches use the same cached index', () async {
    final source = datasource();
    await source.searchAyahs('الله');

    final results = await source.searchAyahs('ذلك الكتاب');

    expect(
      results.map((a) => '${a.surahId}:${a.numberInSurah}'),
      contains('2:2'),
    );
  });
}
