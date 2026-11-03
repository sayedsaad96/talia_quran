import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran_study/data/datasources/approved_study_bundle_source.dart';

void main() {
  Map<String, Object?> metadata(List<int> bytes) => {
    'sourceId': 'fixture',
    'kind': 'tafsir',
    'language': 'ar',
    'workTitle': 'Synthetic fixture',
    'publisher': 'test',
    'edition': '1',
    'sourceUrl': 'https://example.test/item',
    'retrievedAt': '2026-01-01',
    'licenseEvidence': 'test only',
    'licenseCheckedAt': '2026-01-01',
    'reuseScope': 'synthetic fixture only',
    'attributionText': 'fixture',
    'updateObligation': 'fixture',
    'reviewEvidence': 'fixture',
    'reviewedBy': 'test',
    'reviewedAt': '2026-01-01',
    'reviewDecision': 'approved',
    'sha256': sha256.convert(bytes).toString(),
    'footnoteFormat': 'plain',
    'coverage': 'complete',
  };
  List<int> bundle(List<Map<String, Object?>> blocks) =>
      utf8.encode(jsonEncode({'blocks': blocks}));
  Map<String, Object?> block(String id, int from, int to) => {
    'blockId': id,
    'surahId': 1,
    'fromAyah': from,
    'toAyah': to,
    'text': 'Synthetic text',
    'footnotes': ['Synthetic footnote'],
  };
  test('complete blocks preserve range, footnote and overlap', () {
    final bytes = bundle([block('a', 1, 2), block('b', 2, 2)]);
    final result = validateStudyBundle(
      bytes: bytes,
      manifestEntry: metadata(bytes),
      canonicalAyahCounts: {1: 2},
    );
    expect(result.errors, isEmpty);
    expect(result.blocks.first.toAyah, 2);
    expect(result.blocks.first.footnotes, ['Synthetic footnote']);
  });
  test(
    'rejects missing coverage, duplicate IDs, invalid bounds, tampering and approval',
    () {
      for (final blocks in [
        [block('a', 1, 1)],
        [block('a', 1, 2), block('a', 1, 2)],
        [block('a', 0, 2)],
      ]) {
        final bytes = bundle(blocks);
        expect(
          validateStudyBundle(
            bytes: bytes,
            manifestEntry: metadata(bytes),
            canonicalAyahCounts: {1: 2},
          ).errors,
          isNotEmpty,
        );
      }
      final bytes = bundle([block('a', 1, 2)]);
      expect(
        validateStudyBundle(
          bytes: bytes,
          manifestEntry: {...metadata(bytes), 'sha256': 'bad'},
          canonicalAyahCounts: {1: 2},
        ).errors,
        isNotEmpty,
      );
      expect(
        validateStudyBundle(
          bytes: bytes,
          manifestEntry: {...metadata(bytes), 'reviewDecision': 'blocked'},
          canonicalAyahCounts: {1: 2},
        ).errors,
        isNotEmpty,
      );
    },
  );
}
