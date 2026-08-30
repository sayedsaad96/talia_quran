import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/data/models/zikr_model.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';

void main() {
  const releaseAssetPath = 'assets/data/azkar_release.json';
  const categories = {
    'morning': AzkarCategory.morning,
    'evening': AzkarCategory.evening,
    'general': AzkarCategory.general,
    'duas': AzkarCategory.duas,
  };

  group('adhkar release corpus contract', () {
    test('releases all 109 reviewed records without altering their text', () {
      final candidate =
          jsonDecode(File('assets/data/azkar.json').readAsStringSync())
              as Map<String, dynamic>;
      final release =
          jsonDecode(File(releaseAssetPath).readAsStringSync())
              as Map<String, dynamic>;
      const expectedCounts = {
        'morning': 22,
        'evening': 22,
        'general': 31,
        'duas': 34,
      };

      for (final entry in expectedCounts.entries) {
        final candidateRecords = (candidate[entry.key] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final releaseRecords = (release[entry.key] as List<dynamic>)
            .cast<Map<String, dynamic>>();

        expect(releaseRecords, hasLength(entry.value));
        final candidatesById = {
          for (final record in candidateRecords) record['id']: record,
        };
        for (final releaseRecord in releaseRecords) {
          final candidateRecord = candidatesById[releaseRecord['id']];
          expect(
            candidateRecord,
            isNotNull,
            reason: 'missing candidate ${releaseRecord['id']}',
          );
          expect(
            releaseRecord['text'],
            candidateRecord!['text'],
            reason: 'altered text ${releaseRecord['id']}',
          );
        }
      }
    });

    test(
      'the release allowlist is bundled instead of the candidate corpus',
      () {
        final pubspec = File('pubspec.yaml').readAsStringSync();

        expect(pubspec, contains('- assets/data/azkar_release.json'));
        expect(
          RegExp(
            r'^\s*-\s+assets/data/\s*$',
            multiLine: true,
          ).hasMatch(pubspec),
          isFalse,
        );
        expect(File(releaseAssetPath).existsSync(), isTrue);
        expect(File('assets/data/azkar.json').existsSync(), isTrue);
      },
    );

    test('manifest tracks the release allowlist, not the candidate corpus', () {
      final manifest =
          jsonDecode(
                File('assets/data/content_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final paths = (manifest['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((item) => item['path'])
          .toList();

      expect(paths, contains(releaseAssetPath));
      expect(paths, isNot(contains('assets/data/azkar.json')));
    });

    test('all release records are approved and satisfy the strict schema', () {
      final releaseFile = File(releaseAssetPath);
      expect(releaseFile.existsSync(), isTrue);
      final data =
          jsonDecode(releaseFile.readAsStringSync()) as Map<String, dynamic>;
      final ids = <String>{};

      for (final entry in categories.entries) {
        expect(data[entry.key], isA<List<dynamic>>());
        final records = data[entry.key] as List<dynamic>;
        for (final rawRecord in records) {
          final record = rawRecord as Map<String, dynamic>;
          final zikr = ZikrModel.fromJson(record, entry.value);

          expect(ids.add(zikr.id), isTrue, reason: 'duplicate id ${zikr.id}');
          expect(zikr.reviewStatus, ContentReviewStatus.approved);
          expect(zikr.citation, isNotEmpty);
          expect(zikr.sourceType, isNotNull);
          expect(zikr.datasetVersion, isNot('unversioned'));
        }
      }
    });
  });
}
