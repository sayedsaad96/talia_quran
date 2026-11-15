import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';

void main() {
  test('Share Good copy contains no reward or ranking vocabulary', () {
    final forbidden = RegExp(
      r'ثواب|أجر|حسنات|reward|blessing points|leaderboard|ranking',
      caseSensitive: false,
    );
    for (final language in ['ar', 'en']) {
      final values =
          jsonDecode(File('lib/core/l10n/app_$language.arb').readAsStringSync())
              as Map<String, dynamic>;
      final relevant = values.entries.where(
        (entry) =>
            RegExp(r'^(invite|shareGood|goodImpact)').hasMatch(entry.key),
      );
      expect(relevant, isNotEmpty);
      for (final entry in relevant) {
        expect(
          forbidden.hasMatch(entry.value.toString()),
          isFalse,
          reason: '${entry.key} ($language)',
        );
      }
    }
  });
  test('Arabic aggregate plurals cover zero one two few many and other', () {
    final l10n = lookupAppLocalizations(const Locale('ar'));
    for (final count in [0, 1, 2, 3, 11, 100]) {
      for (final text in [
        l10n.goodImpactResponses(count),
        l10n.goodImpactCompletions(count),
        l10n.goodImpactReach(count),
      ]) {
        expect(text.trim(), isNotEmpty);
        expect(text, isNot(contains('{')));
      }
    }
    expect(l10n.goodImpactResponses(1), isNot(l10n.goodImpactResponses(2)));
    expect(l10n.goodImpactCompletions(1), isNot(l10n.goodImpactCompletions(2)));
  });
}
