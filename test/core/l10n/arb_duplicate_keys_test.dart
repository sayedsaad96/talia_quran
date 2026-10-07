import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// JSON keeps only the last of two equal keys, so a duplicate in an ARB file
/// silently hides the first translation (six such keys were found on
/// 2026-10-07, e.g. two different `splashTagline` values).
void main() {
  for (final path in const [
    'lib/core/l10n/app_ar.arb',
    'lib/core/l10n/app_en.arb',
  ]) {
    test('$path has no duplicate keys', () {
      final keyLine = RegExp(r'^  "([^"]+)":', multiLine: true);
      final seen = <String>{};
      final duplicates = <String>{};
      for (final match in keyLine.allMatches(File(path).readAsStringSync())) {
        final key = match.group(1)!;
        if (!seen.add(key)) duplicates.add(key);
      }

      expect(duplicates, isEmpty);
    });
  }
}
