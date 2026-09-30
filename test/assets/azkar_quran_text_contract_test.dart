import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reduces Arabic text to its consonant skeleton so records written in plain
/// spelling still compare equal to the Uthmani corpus. It drops diacritics,
/// tatweel (U+0640), and the alef, waw, yaa, hamza, ta marbuta and ha families.
String _skeleton(String text) {
  final letters = text.replaceAll(RegExp(r'[^ء-غف-ي]'), '');
  return letters.replaceAll(RegExp('[ءاأإآٱوؤيئىةه]'), '');
}

void main() {
  test('every Quran-type azkar record exists in quran.json', () {
    final release =
        jsonDecode(File('assets/data/azkar_release.json').readAsStringSync())
            as Map<String, dynamic>;
    final quran =
        jsonDecode(File('assets/data/quran.json').readAsStringSync())
            as Map<String, dynamic>;

    final corpus = StringBuffer();
    for (final surah in quran.values) {
      for (final ayah
          in (surah as List<dynamic>).cast<Map<String, dynamic>>()) {
        corpus.write(_skeleton(ayah['text'] as String));
      }
    }
    final corpusText = corpus.toString();

    // Recitation openers that are not part of the quoted ayah.
    final openers = [
      _skeleton('أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ'),
      _skeleton('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
    ];

    var checked = 0;
    final missing = <String>[];
    for (final records in release.values) {
      for (final record
          in (records as List<dynamic>).cast<Map<String, dynamic>>()) {
        if (record['sourceType'] != 'quran') continue;
        checked++;
        var skeleton = _skeleton(record['text'] as String);
        for (final opener in openers) {
          skeleton = skeleton.replaceAll(opener, '');
        }
        if (!corpusText.contains(skeleton)) {
          missing.add('${record['id']} (${record['reference']})');
        }
      }
    }

    expect(
      checked,
      greaterThan(20),
      reason: 'the check must not pass vacuously',
    );
    expect(
      missing,
      isEmpty,
      reason:
          'Quran text not found in quran.json. Report these to the owner; '
          'never correct religious text from memory.',
    );
  });

  test('the skeleton comparison detects a changed word', () {
    final original = _skeleton('رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً');
    final altered = _skeleton('رَبَّنَا آتِنَا فِي الدُّنْيَا سَيِّئَةً');

    expect(altered, isNot(original));
  });
}
