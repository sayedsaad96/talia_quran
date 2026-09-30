import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/data/models/zikr_model.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_dedupe.dart';

void main() {
  const categories = {
    'morning': AzkarCategory.morning,
    'evening': AzkarCategory.evening,
    'general': AzkarCategory.general,
    'duas': AzkarCategory.duas,
  };

  final release =
      jsonDecode(File('assets/data/azkar_release.json').readAsStringSync())
          as Map<String, dynamic>;

  DedupedAzkar dedupe(String key) {
    final records = (release[key] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((json) => ZikrModel.fromJson(json, categories[key]!))
        .toList();
    return AzkarDedupe.apply(records);
  }

  test('the duas library hides exactly the five verified repeats', () {
    final result = dedupe('duas');

    // If this fails, read both texts before changing the expected set: a
    // repeat that appears or disappears means the release data changed.
    expect(result.aliases, {
      'dq1': {'dua_quran_1'},
      'dq2': {'dua_quran_2'},
      'dp1': {'dua_prophet_1'},
      'dp2': {'dua_prophet_2'},
      'dp6': {'dua_prophet_3'},
    });
    expect(result.items, hasLength(34 - 5));
  });

  test('no other category loses a record to deduplication', () {
    for (final key in const ['morning', 'evening', 'general']) {
      expect(dedupe(key).aliases, isEmpty, reason: key);
    }
  });

  test('Ta-Ha 25:28 and Ta-Ha 25-26 are distinct records and both stay', () {
    final ids = dedupe('duas').items.map((z) => z.id).toSet();

    expect(ids, containsAll(['dq4', 'dua_quran_3']));
  });
}
