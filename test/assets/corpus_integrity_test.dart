import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/utils/arabic_normalizer.dart';

/// V1-M1 / V1-M2 release gates — Quran corpus integrity and content manifest.
///
/// These tests read the real bundled assets and fail closed on any drift from
/// the frozen manifest or any violation of the approved ayah-1 basmalah
/// boundaries:
///   - Al-Fatihah ayah 1 IS the basmalah (numbered ayah).
///   - At-Tawbah has no basmalah.
///   - Every other surah's ayah 1 contains only the numbered ayah text;
///     the basmalah is handled structurally, never embedded.
void main() {
  group('Quran corpus integrity', () {
    late final Map<String, dynamic> quran;
    late final List<dynamic> surahs;

    setUpAll(() {
      quran =
          jsonDecode(File('assets/data/quran.json').readAsStringSync())
              as Map<String, dynamic>;
      surahs =
          jsonDecode(File('assets/data/surahs.json').readAsStringSync())
              as List<dynamic>;
    });

    String normalizedAyahText(Map<String, dynamic> ayah) =>
        ArabicNormalizer.normalize(ayah['text'] as String);

    test('contains exactly 114 surahs and 6236 ayahs', () {
      expect(quran.keys.length, 114);
      final totalAyahs = quran.values.fold<int>(
        0,
        (sum, list) => sum + (list as List).length,
      );
      expect(totalAyahs, 6236);
    });

    test('per-surah verse counts match surahs.json', () {
      expect(surahs.length, 114);
      for (final surah in surahs) {
        final id = surah['id'] as int;
        final expectedCount = surah['ayahCount'] as int;
        final ayahs = quran[id.toString()] as List?;
        expect(ayahs, isNotNull, reason: 'Surah $id missing from quran.json');
        expect(
          ayahs!.length,
          expectedCount,
          reason: 'Surah $id ayah count mismatch',
        );
      }
    });

    test('surah boundaries, first pages and first juz match surahs.json', () {
      for (final rawSurah in surahs) {
        final surah = rawSurah as Map<String, dynamic>;
        final id = surah['id'] as int;
        final ayahs = (quran[id.toString()] as List)
            .cast<Map<String, dynamic>>();

        expect(
          ayahs.first['chapter'],
          id,
          reason: 'Surah $id starts in the wrong chapter',
        );
        expect(
          ayahs.first['verse'],
          1,
          reason: 'Surah $id does not start at ayah 1',
        );
        expect(
          ayahs.last['verse'],
          surah['ayahCount'],
          reason: 'Surah $id ends at the wrong ayah boundary',
        );
        expect(
          ayahs.first['page'],
          surah['page'],
          reason: 'Surah $id first page disagrees with surahs.json',
        );
        expect(
          ayahs.first['juz'],
          surah['juz'],
          reason: 'Surah $id first juz disagrees with surahs.json',
        );
      }
    });

    test('global ayah numbers are contiguous from 1 to 6236 in order', () {
      var expectedGlobal = 1;
      for (var surahId = 1; surahId <= 114; surahId++) {
        final ayahs = quran[surahId.toString()] as List;
        for (final ayah in ayahs) {
          expect(
            ayah['global'],
            expectedGlobal,
            reason: 'Surah $surahId global sequence broken',
          );
          expectedGlobal++;
        }
      }
      expect(expectedGlobal, 6237);
    });

    test('verse numbers are 1-based and contiguous within each surah', () {
      for (var surahId = 1; surahId <= 114; surahId++) {
        final ayahs = quran[surahId.toString()] as List;
        for (var i = 0; i < ayahs.length; i++) {
          expect(
            ayahs[i]['verse'],
            i + 1,
            reason: 'Surah $surahId verse numbering broken',
          );
          expect(ayahs[i]['chapter'], surahId);
        }
      }
    });

    test('pages cover exactly 1-604 and juz cover exactly 1-30', () {
      final pages = <int>{};
      final juz = <int>{};
      for (final ayahs in quran.values) {
        for (final ayah in ayahs as List) {
          pages.add(ayah['page'] as int);
          juz.add(ayah['juz'] as int);
        }
      }
      expect(pages.reduce((a, b) => a < b ? a : b), 1);
      expect(pages.reduce((a, b) => a > b ? a : b), 604);
      expect(juz.reduce((a, b) => a < b ? a : b), 1);
      expect(juz.reduce((a, b) => a > b ? a : b), 30);
    });

    test('every ayah record carries non-null structural metadata', () {
      for (final entry in quran.entries) {
        for (final ayah in entry.value as List) {
          expect(
            ayah['text'],
            isA<String>(),
            reason: 'Surah ${entry.key}: missing text',
          );
          expect(
            (ayah['text'] as String).isNotEmpty,
            isTrue,
            reason: 'Surah ${entry.key}: empty text',
          );
          expect(
            ayah['global'],
            isA<int>(),
            reason: 'Surah ${entry.key}: missing global',
          );
          expect(
            ayah['page'],
            isA<int>(),
            reason: 'Surah ${entry.key}: missing page',
          );
          expect(
            ayah['juz'],
            isA<int>(),
            reason: 'Surah ${entry.key}: missing juz',
          );
        }
      }
    });

    test(
      'Al-Fatihah ayah 1 retains its approved numbered-basmalah convention',
      () {
        final ayah1 = (quran['1'] as List)[0] as Map<String, dynamic>;
        expect(
          normalizedAyahText(ayah1),
          startsWith('بسم الله الرحمان الرحيم'),
        );
      },
    );

    test('At-Tawbah contains no basmalah anywhere in ayah 1', () {
      final ayah1 = (quran['9'] as List)[0] as Map<String, dynamic>;
      expect(
        normalizedAyahText(ayah1),
        isNot(contains('بسم الله')),
        reason: 'At-Tawbah must not embed the basmalah',
      );
    });

    test('no surah other than Al-Fatihah embeds the basmalah in ayah 1 '
        '(basmalah is structural, not part of the numbered ayah)', () {
      for (var surahId = 2; surahId <= 114; surahId++) {
        if (surahId == 9) continue;
        final ayah1 =
            (quran[surahId.toString()] as List)[0] as Map<String, dynamic>;
        expect(
          normalizedAyahText(ayah1),
          isNot(startsWith('بسم الله')),
          reason:
              'Surah $surahId ayah 1 still embeds the basmalah prefix: '
              '${ayah1['text']}',
        );
      }
    });

    test('runtime SHA-256 matches the frozen content manifest', () {
      final manifest =
          jsonDecode(
                File('assets/data/content_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final quranEntry = (manifest['items'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((item) => item['path'] == 'assets/data/quran.json');

      final bytes = File('assets/data/quran.json').readAsBytesSync();
      expect(sha256.convert(bytes).toString(), quranEntry['sha256']);
    });
  });

  group('Content manifest contract (V1-M2)', () {
    late final Map<String, dynamic> manifest;

    setUpAll(() {
      manifest =
          jsonDecode(
                File('assets/data/content_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
    });

    const allowedReviewStates = {'pendingReview', 'approved', 'rejected'};
    const requiredItemFields = [
      'path',
      'role',
      'sourceProvider',
      'licenseStatus',
      'sha256',
      'importDate',
      'reviewStatus',
    ];

    test('manifest carries dataset version, freeze date and review state', () {
      expect(manifest['datasetVersion'], isA<String>());
      expect((manifest['datasetVersion'] as String).isNotEmpty, isTrue);
      expect(manifest['freezeDate'], isA<String>());
      expect(manifest['reviewStatus'], isIn(allowedReviewStates));
    });

    test('every item satisfies required schema fields', () {
      final items = manifest['items'] as List;
      expect(items.length, greaterThanOrEqualTo(3));
      for (final item in items.cast<Map<String, dynamic>>()) {
        for (final field in requiredItemFields) {
          expect(
            item[field],
            isNotNull,
            reason: '${item['path']} missing $field',
          );
        }
        expect(
          item['reviewStatus'],
          isIn(allowedReviewStates),
          reason: '${item['path']} has invalid reviewStatus',
        );
        expect(
          RegExp(r'^[0-9a-f]{64}$').hasMatch(item['sha256'] as String),
          isTrue,
          reason: '${item['path']} sha256 is not a lowercase hex digest',
        );
      }
    });

    test('Quran entries declare riwayah; every hash matches on-disk bytes', () {
      for (final item
          in (manifest['items'] as List).cast<Map<String, dynamic>>()) {
        if (item['role'] == 'quran_text' || item['role'] == 'quran_structure') {
          expect(item['riwayah'], isNotNull);
          expect(
            (item['riwayah'] as String).contains('hafs'),
            isTrue,
            reason: 'V1 pins one declared riwayah (Hafs)',
          );
        }
        final file = File(item['path'] as String);
        expect(
          file.existsSync(),
          isTrue,
          reason: '${item['path']} listed in manifest but missing',
        );
        expect(
          sha256.convert(file.readAsBytesSync()).toString(),
          item['sha256'],
          reason: '${item['path']} drifted from the frozen manifest',
        );
      }
    });

    test('quran_structure declares its derivation from the frozen corpus', () {
      final structureEntry = (manifest['items'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((item) => item['role'] == 'quran_structure');

      expect(
        structureEntry['sourceProvider'],
        'project_derived_from_frozen_quran_corpus',
      );
      expect(structureEntry['sourceEdition'], 'derived_structural_index');
      expect(structureEntry['derivedFrom'], 'assets/data/quran.json');
      expect(structureEntry['crossCheckedFields'], [
        'surah_boundaries',
        'page',
        'juz',
      ]);
    });

    test('runtime QCF corpus identity matches the locked dependency', () {
      expect(manifest['runtimeQuranRenderingCorpus'], isA<Map>());
      final renderingCorpus = Map<String, dynamic>.from(
        manifest['runtimeQuranRenderingCorpus'] as Map,
      );
      final lockText = File('pubspec.lock').readAsStringSync();
      final lockedPackage = RegExp(
        r'^  qcf_quran_plus:\s*$([\s\S]*?)(?=^  [a-zA-Z0-9_]+:|\z)',
        multiLine: true,
      ).firstMatch(lockText)!.group(1)!;
      final lockedVersion = RegExp(
        r'^    version: "([^"]+)"',
        multiLine: true,
      ).firstMatch(lockedPackage)!.group(1)!;
      final lockedSha256 = RegExp(
        r'^      sha256: "?([0-9a-f]{64})"?',
        multiLine: true,
      ).firstMatch(lockedPackage)!.group(1)!;

      expect(renderingCorpus['role'], 'quran_runtime_rendering_corpus');
      expect(renderingCorpus['package'], 'qcf_quran_plus');
      expect(renderingCorpus['dependencyVersion'], lockedVersion);
      expect(renderingCorpus['lockedSha256'], lockedSha256);
      expect(
        renderingCorpus['lockedSha256'],
        'a1a3dbe3ce0cdd9298dfc59cc00bb1c0f6405d19fce9cf1bf222588b9555b9ce',
      );
      expect(
        renderingCorpus['sourceUrl'],
        'https://github.com/hussein12347/qcf_quran_plus',
      );
      expect(renderingCorpus['riwayah'], 'hafs');
      expect(renderingCorpus['licenseStatus'], 'MIT');
      expect(renderingCorpus['freezeDate'], manifest['freezeDate']);
      expect(renderingCorpus['reviewStatus'], isIn(allowedReviewStates));
    });
  });
}
