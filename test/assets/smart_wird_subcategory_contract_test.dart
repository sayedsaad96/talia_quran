import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/services/smart_wird_general_policy.dart';

void main() {
  test('every general subcategory is classified by the smart-wird policy', () {
    final release =
        jsonDecode(File('assets/data/azkar_release.json').readAsStringSync())
            as Map<String, dynamic>;
    final classified = {
      ...SmartWirdGeneralPolicy.situational,
      ...SmartWirdGeneralPolicy.alwaysIncluded,
      SmartWirdGeneralPolicy.sleep,
      SmartWirdGeneralPolicy.waking,
    };

    final unclassified = <String>{};
    for (final record
        in (release['general'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final sub = record['subcategory'] as String? ?? '';
      if (sub.isNotEmpty && !classified.contains(sub)) unclassified.add(sub);
    }

    expect(
      unclassified,
      isEmpty,
      reason:
          'New general subcategory: decide whether it belongs in a daily '
          'wird and add it to SmartWirdGeneralPolicy.',
    );
  });
}
