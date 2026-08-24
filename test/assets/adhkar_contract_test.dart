import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/data/models/zikr_model.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';

/// V1-M3 — adhkar/dua provenance contract.
///
/// Engineering gate: every shipped record carries the required governance
/// fields and a valid review state. Record-level religious dispositions
/// (grade, citation, tier values) are assigned exclusively by the qualified
/// Islamic reviewer and remain null / pendingReview until then.
void main() {
  late final Map<String, dynamic> data;

  setUpAll(() {
    data =
        jsonDecode(File('assets/data/azkar.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  const categories = {
    'morning': AzkarCategory.morning,
    'evening': AzkarCategory.evening,
    'general': AzkarCategory.general,
    'duas': AzkarCategory.duas,
  };

  group('adhkar corpus contract', () {
    test('all four categories exist and every record parses', () {
      for (final entry in categories.entries) {
        final records = data[entry.key] as List;
        expect(records, isNotEmpty, reason: '${entry.key} is empty');
        for (final record in records) {
          expect(
            () => ZikrModel.fromJson(
              record as Map<String, dynamic>,
              entry.value,
              datasetVersion: 'v1-rc1',
            ),
            returnsNormally,
          );
        }
      }
    });

    test('every retained record satisfies schema rules', () {
      final ids = <String>{};
      var total = 0;
      for (final entry in categories.entries) {
        for (final record in data[entry.key] as List) {
          total++;
          final zikr = ZikrModel.fromJson(
            record as Map<String, dynamic>,
            entry.value,
            datasetVersion: 'v1-rc1',
          );

          // Identity + content.
          expect(zikr.id, isNotEmpty);
          expect(ids.add(zikr.id), isTrue,
              reason: 'duplicate record id ${zikr.id}');
          expect(zikr.text.trim(), isNotEmpty);
          expect(zikr.totalCount, greaterThanOrEqualTo(1));

          // Governance fields must exist on the record.
          expect(record.keys, containsAll([
            'citation',
            'sourceType',
            'authenticityGrade',
            'tier',
            'datasetVersion',
            'reviewStatus',
          ]), reason: 'record ${zikr.id} missing governance fields');

          // Dataset version pinned to the frozen release candidate.
          expect(zikr.datasetVersion, 'v1-rc1');

          // Review state is a valid enum value.
          expect(zikr.reviewStatus, isA<ContentReviewStatus>());

          // Optional religious metadata is null or a valid value.
          if (zikr.sourceType != null) {
            expect(
              zikr.sourceType,
              anyOf('quran', 'hadith', 'dhikr', 'dua'),
            );
          }
          if (zikr.tier != null) {
            expect(DuaTier.values.map((t) => t.name), contains(zikr.tier!.name));
          }
        }
      }
      expect(total, 85);
    });
  });
}
