import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';

void main() {
  late final String quranJsonStr;
  late final List<SurahModel> allSurahs;
  late final QuranParseResult parsedCorpus;

  setUpAll(() {
    quranJsonStr = File('assets/data/quran.json').readAsStringSync();
    final surahsRaw = jsonDecode(File('assets/data/surahs.json').readAsStringSync()) as List<dynamic>;
    allSurahs = surahsRaw.map((s) => SurahModel.fromJson(s as Map<String, dynamic>)).toList();

    parsedCorpus = QuranLocalDatasourceImpl.parseQuranData({
      'jsonStr': quranJsonStr,
      'surahs': allSurahs,
    });
  });

  group('Quran Corpus Integrity — All 114 Surahs and 604 Pages', () {
    test('all 114 surahs are present and indexed', () {
      expect(allSurahs.length, 114);
      expect(parsedCorpus.ayahs.keys.length, 114);
      for (int i = 1; i <= 114; i++) {
        expect(parsedCorpus.ayahs.containsKey(i), isTrue, reason: 'Surah $i missing from corpus');
        expect(parsedCorpus.ayahs[i]!.isNotEmpty, isTrue, reason: 'Surah $i has no ayahs');
      }
    });

    test('all 604 Mushaf pages have ayahs and no page is empty', () {
      expect(parsedCorpus.byPage.keys.length, 604);
      for (int page = 1; page <= 604; page++) {
        final pageAyahs = parsedCorpus.byPage[page];
        expect(pageAyahs, isNotNull, reason: 'Page $page is missing from page index');
        expect(pageAyahs!.isNotEmpty, isTrue, reason: 'Page $page has no ayahs');
      }
    });

    test('every ayah in all 114 surahs can be resolved on its Mushaf page', () {
      int totalAyahCount = 0;

      for (final surah in allSurahs) {
        final ayahs = parsedCorpus.ayahs[surah.id]!;
        expect(ayahs.length, surah.ayahCount,
            reason: 'Surah ${surah.id} (${surah.nameAr}) ayah count mismatch: expected ${surah.ayahCount}, got ${ayahs.length}');

        for (final ayah in ayahs) {
          totalAyahCount++;
          final pageAyahs = parsedCorpus.byPage[ayah.page]!;

          // Simulate _resolveAyah logic
          final resolved = pageAyahs.where(
            (a) => a.surahId == ayah.surahId && a.numberInSurah == ayah.numberInSurah,
          ).firstOrNull;

          expect(
            resolved,
            isNotNull,
            reason: 'Could not resolve Surah ${ayah.surahId} Ayah ${ayah.numberInSurah} on Page ${ayah.page}',
          );
          expect(resolved!.text.trim().isNotEmpty, isTrue);
          expect(resolved.text, ayah.text);
        }
      }

      // 6236 ayahs in the Hafs standard Quran
      expect(totalAyahCount, 6236);
    });

    test('every ayah resolves on the page the reader draws it on (QCF layout)', () {
      // The reader long-press and page playback look an ayah up on the page
      // returned by qcf.getPageNumber, so the page index must agree with it.
      for (final surah in allSurahs) {
        for (final ayah in parsedCorpus.ayahs[surah.id]!) {
          final drawnPage = qcf.getPageNumber(ayah.surahId, ayah.numberInSurah);
          expect(ayah.page, drawnPage,
              reason: '${ayah.surahId}:${ayah.numberInSurah} page index '
                  '${ayah.page} differs from drawn page $drawnPage');
          final onPage = parsedCorpus.byPage[drawnPage]!.where(
            (a) => a.surahId == ayah.surahId && a.numberInSurah == ayah.numberInSurah,
          );
          expect(onPage, hasLength(1),
              reason: '${ayah.surahId}:${ayah.numberInSurah} not on page $drawnPage');
        }
      }
    });

    test('page-boundary ayah 5:77 sits on page 120, as the reader draws it', () {
      List<String> keys(int page) => parsedCorpus.byPage[page]!
          .map((a) => '${a.surahId}:${a.numberInSurah}')
          .toList();

      expect(keys(120).last, '5:77');
      expect(keys(121).first, '5:78');
    });

    test('qcf.getSurahNameArabic returns valid Arabic name for all 114 surahs', () {
      for (int surahId = 1; surahId <= 114; surahId++) {
        final arabicName = qcf.getSurahNameArabic(surahId);
        expect(arabicName, isNotEmpty, reason: 'Surah $surahId Arabic name is empty');
        expect(arabicName.trim(), isNotEmpty);
      }
    });

    test('multi-surah pages (like Page 604 with Surahs 112, 113, 114) resolve every ayah in every surah correctly', () {
      final page604 = parsedCorpus.byPage[604]!;
      final surahsOn604 = page604.map((a) => a.surahId).toSet();
      expect(surahsOn604, {112, 113, 114});

      // Verify each ayah in Al-Ikhlas (112), Al-Falaq (113), and An-Nas (114) resolves without collision
      for (int surahId in [112, 113, 114]) {
        final surahAyahs = parsedCorpus.ayahs[surahId]!;
        for (final ayah in surahAyahs) {
          final matched = page604.where(
            (a) => a.surahId == surahId && a.numberInSurah == ayah.numberInSurah,
          ).firstOrNull;
          expect(matched, isNotNull);
          expect(matched!.surahId, surahId);
          expect(matched.numberInSurah, ayah.numberInSurah);
        }
      }
    });

    test('Surah At-Tawbah (9) on Page 187 resolves without error', () {
      final page187 = parsedCorpus.byPage[187]!;
      final firstAyah = page187.where((a) => a.surahId == 9 && a.numberInSurah == 1).firstOrNull;
      expect(firstAyah, isNotNull);
      expect(firstAyah!.text.startsWith('بَرَآءَةٌۭ'), isTrue);
    });
  });
}
