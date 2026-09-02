import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const candidatePath = 'assets/data/azkar.json';
  const releasePath = 'assets/data/azkar_release.json';
  const expansionVersion = 'v1-candidate-2';
  const expectedExpansionIds = {
    'gen_enter_toilet',
    'gen_leave_toilet',
    'gen_leave_home',
    'gen_food_forgot_bismillah',
    'gen_travel',
    'gen_distress',
    'gen_visit_sick',
    'gen_expiation_gathering',
    'gen_rain',
    'gen_after_rain',
    'gen_wind',
    'gen_anger',
    'dua_quran_2_127',
    'dua_quran_2_250',
    'dua_quran_2_286',
    'dua_quran_3_147',
    'dua_quran_7_151',
    'dua_quran_14_41',
    'dua_quran_17_24',
    'dua_quran_18_10',
    'dua_quran_20_114',
    'dua_quran_21_87',
    'dua_quran_28_24',
    'dua_quran_59_10',
  };

  group('adhkar expansion candidate', () {
    late Map<String, dynamic> candidate;
    late List<Map<String, dynamic>> allCandidateRecords;
    late List<Map<String, dynamic>> expansionRecords;

    setUpAll(() {
      candidate = _readJsonMap(candidatePath);
      allCandidateRecords = _allRecords(candidate);
      expansionRecords = allCandidateRecords
          .where((record) => record['datasetVersion'] == expansionVersion)
          .toList();
    });

    test('adds exactly 24 records in the intended categories', () {
      expect((candidate['morning'] as List<dynamic>), hasLength(22));
      expect((candidate['evening'] as List<dynamic>), hasLength(22));
      expect((candidate['general'] as List<dynamic>), hasLength(31));
      expect((candidate['duas'] as List<dynamic>), hasLength(34));
      expect(expansionRecords, hasLength(24));
      expect(
        expansionRecords.map((record) => record['id']).toSet(),
        expectedExpansionIds,
      );
    });

    test('keeps every new record pending with complete review evidence', () {
      for (final record in expansionRecords) {
        expect(record['reviewStatus'], 'pendingReview', reason: record['id']);
        expect(record['authenticityGrade'], isNull, reason: record['id']);
        expect(record['tier'], isNull, reason: record['id']);
        expect(record['count'], 1, reason: record['id']);
        for (final field in [
          'text',
          'reference',
          'citation',
          'sourceType',
          'sourceUrl',
        ]) {
          expect(
            (record[field] as String?)?.trim(),
            isNotEmpty,
            reason: '${record['id']} is missing $field',
          );
        }
      }
      expect(
        expansionRecords.where((record) => record['sourceType'] == 'hadith'),
        hasLength(12),
      );
      expect(
        expansionRecords.where((record) => record['sourceType'] == 'quran'),
        hasLength(12),
      );
    });

    test('does not add a normalized duplicate', () {
      final oldRecords = allCandidateRecords
          .where((record) => record['datasetVersion'] != expansionVersion)
          .toList();
      final oldTexts = oldRecords
          .map((record) => _normalizeArabic(record['text'] as String))
          .toSet();
      final newTexts = <String>{};

      for (final record in expansionRecords) {
        final normalized = _normalizeArabic(record['text'] as String);
        expect(normalized, isNotEmpty, reason: record['id']);
        expect(oldTexts, isNot(contains(normalized)), reason: record['id']);
        expect(newTexts.add(normalized), isTrue, reason: record['id']);
      }
    });

    test('copies every Quranic dua exactly from its cited local ayah', () {
      final quran = _readJsonMap('assets/data/quran.json');

      for (final record in expansionRecords.where(
        (record) => record['sourceType'] == 'quran',
      )) {
        final citation = record['citation'] as String;
        final match = RegExp(r'^القرآن (\d+):(\d+)$').firstMatch(citation);
        expect(match, isNotNull, reason: record['id']);
        final surah = match!.group(1)!;
        final ayahNumber = int.parse(match.group(2)!);
        final ayah = (quran[surah] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .singleWhere((item) => item['verse'] == ayahNumber);

        expect(
          ayah['text'] as String,
          contains(record['text'] as String),
          reason: record['id'],
        );
      }
    });

    test('publishes the approved expansion without altering review data', () {
      final releaseRecords = _allRecords(_readJsonMap(releasePath));
      final releasedExpansion = releaseRecords
          .where((record) => expectedExpansionIds.contains(record['id']))
          .toList();
      final candidatesById = {
        for (final record in expansionRecords) record['id']: record,
      };

      expect(releaseRecords, hasLength(109));
      expect(releasedExpansion, hasLength(24));
      expect(
        releasedExpansion.map((record) => record['id']).toSet(),
        expectedExpansionIds,
      );
      for (final releaseRecord in releasedExpansion) {
        final candidateRecord = candidatesById[releaseRecord['id']]!;
        expect(releaseRecord['reviewStatus'], 'approved');
        expect(releaseRecord['datasetVersion'], 'v1-reviewed-2');
        for (final field in [
          'text',
          'transliteration',
          'translation',
          'count',
          'reference',
          'subcategory',
          'citation',
          'sourceType',
          'sourceUrl',
          'authenticityGrade',
          'tier',
        ]) {
          expect(
            releaseRecord[field],
            candidateRecord[field],
            reason: '${releaseRecord['id']} changed $field',
          );
        }
      }
    });

    test('manifest fingerprints the 109-record release allowlist', () {
      final manifest = _readJsonMap('assets/data/content_manifest.json');
      final releaseEntry = (manifest['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((entry) => entry['path'] == releasePath);
      final releaseDigest = sha256
          .convert(File(releasePath).readAsBytesSync())
          .toString();

      expect(
        releaseEntry['sourceEdition'],
        'all_109_records_project_owner_approved',
      );
      expect(releaseEntry['reviewStatus'], 'approved');
      expect(releaseEntry['sha256'], releaseDigest);
    });
  });
}

Map<String, dynamic> _readJsonMap(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

List<Map<String, dynamic>> _allRecords(Map<String, dynamic> data) {
  return ['morning', 'evening', 'general', 'duas']
      .expand(
        (category) =>
            (data[category] as List<dynamic>).cast<Map<String, dynamic>>(),
      )
      .toList();
}

String _normalizeArabic(String text) {
  return text
      .replaceAll(
        RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'),
        '',
      )
      .replaceAll(RegExp(r'[\s\u060C\u061B\u061F.،؛:!?ۖۗۚ۞۝]'), '')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا');
}
