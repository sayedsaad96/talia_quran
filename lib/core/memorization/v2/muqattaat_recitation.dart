// lib/core/memorization/v2/muqattaat_recitation.dart
//
// Pure matching aid for the disjoint letters (الحروف المقطعة) such as «الٓمٓ».
// They are written as one token but recited letter by letter by name
// («ألف لام ميم»), so on-device STT transcribes the spoken names. This file
// never changes or displays Quran text: it only lets a spoken run of letter
// names count as the written token when scoring a recitation.

import '../../../core/utils/arabic_normalizer.dart';

abstract final class MuqattaatRecitation {
  /// A disjoint-letter token in the canonical Tanzil text is made only of
  /// these letters plus the maddah sign (U+0653), with no harakat. In the
  /// bundled corpus this matches exactly the 30 disjoint-letter tokens and no
  /// other word (guarded by
  /// `test/core/memorization/v2/muqattaat_recitation_test.dart`).
  static final RegExp _muqattaatToken = RegExp(
    '^[المصركهيعطسحقن${String.fromCharCode(_maddahAbove)}]+\$',
  );

  /// ARABIC MADDAH ABOVE, kept as a code point because it is invisible.
  static const int _maddahAbove = 0x0653;

  /// Spoken letter names in their [ArabicNormalizer] form (أ→ا), with the
  /// common STT spellings of the names that end in a hamza.
  static const Map<String, List<String>> _letterNames = {
    'ا': ['الف'],
    'ل': ['لام'],
    'م': ['ميم'],
    'ص': ['صاد'],
    'ر': ['راء', 'را'],
    'ك': ['كاف'],
    'ه': ['هاء', 'ها'],
    'ي': ['ياء', 'يا'],
    'ع': ['عين'],
    'ط': ['طاء', 'طا'],
    'س': ['سين'],
    'ح': ['حاء', 'حا'],
    'ق': ['قاف'],
    'ن': ['نون'],
  };

  static bool isMuqattaatToken(String rawToken) =>
      _muqattaatToken.hasMatch(rawToken);

  /// Collapses spoken letter-name runs into the disjoint-letter tokens of
  /// [rawTargetTokens], in target order.
  ///
  /// [normalizedSpokenTokens] are the spoken words after [ArabicNormalizer].
  /// Each returned span names the source spoken range `[start, end)` and the
  /// token to compare; untouched words map to themselves. A spoken run is
  /// only collapsed when its names spell exactly the letters of a target
  /// disjoint-letter token, so ordinary words are never rewritten.
  static List<({String token, int start, int end})> collapseSpoken({
    required List<String> rawTargetTokens,
    required List<String> normalizedSpokenTokens,
  }) {
    final replacements = <int, ({String token, int end})>{};
    var cursor = 0;
    for (final rawToken in rawTargetTokens) {
      if (!isMuqattaatToken(rawToken)) continue;
      final letters = ArabicNormalizer.normalize(rawToken);
      final pattern = _spokenPattern(letters);
      if (pattern == null) continue;
      final match = _findRun(normalizedSpokenTokens, cursor, letters, pattern);
      if (match == null) continue;
      replacements[match.start] = (token: letters, end: match.end);
      cursor = match.end;
    }

    final spans = <({String token, int start, int end})>[];
    var index = 0;
    while (index < normalizedSpokenTokens.length) {
      final replacement = replacements[index];
      if (replacement != null) {
        spans.add((
          token: replacement.token,
          start: index,
          end: replacement.end,
        ));
        index = replacement.end;
      } else {
        spans.add((
          token: normalizedSpokenTokens[index],
          start: index,
          end: index + 1,
        ));
        index++;
      }
    }
    return spans;
  }

  /// `^(name|name)(name)…$` over the spoken names joined without spaces, so
  /// «ياسين», «يا سين» and «ياء سين» all spell «يس».
  static RegExp? _spokenPattern(String letters) {
    final buffer = StringBuffer('^');
    for (final letter in letters.split('')) {
      final names = _letterNames[letter];
      if (names == null) return null;
      buffer.write('(?:${names.join('|')})');
    }
    buffer.write(r'$');
    return RegExp(buffer.toString());
  }

  /// First spoken run at or after [from] that either is the written token
  /// itself or spells its letter names. Each letter name is at most one
  /// spoken word, so a run never spans more words than [letters] has letters.
  static ({int start, int end})? _findRun(
    List<String> spoken,
    int from,
    String letters,
    RegExp pattern,
  ) {
    for (var start = from; start < spoken.length; start++) {
      if (spoken[start] == letters) return (start: start, end: start + 1);
      final buffer = StringBuffer();
      final limit = start + letters.length;
      for (var end = start + 1; end <= limit && end <= spoken.length; end++) {
        buffer.write(spoken[end - 1]);
        if (pattern.hasMatch(buffer.toString())) {
          return (start: start, end: end);
        }
      }
    }
    return null;
  }
}
