import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/muqattaat_recitation.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/v2/recitation_word_diff.dart';
import 'package:talia_quran/core/quran/quran_basmalah.dart';
import 'package:talia_quran/core/utils/arabic_normalizer.dart';

/// Disjoint letters («الٓمٓ») are recited by letter name, so STT returns the
/// names. Ayah text is read from the bundled canonical corpus, never typed.
void main() {
  late Map<String, dynamic> corpus;
  late String basmalahReference;

  setUpAll(() {
    corpus =
        jsonDecode(File('assets/data/quran.json').readAsStringSync())
            as Map<String, dynamic>;
    basmalahReference = ArabicNormalizer.normalize(
      (corpus['1'] as List).first['text'] as String,
    );
  });

  /// The runtime ayah body (`Ayah.text`), basmalah separated as the app does.
  String ayahBody(int surah, int ayah) {
    final record = (corpus['$surah'] as List).firstWhere(
      (verse) => verse['verse'] == ayah,
    );
    return QuranBasmalah.split(
      surahId: surah,
      ayahNumber: ayah,
      canonicalText: record['text'] as String,
      normalizedReference: basmalahReference,
    ).body;
  }

  List<String> tokens(String text) =>
      text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  // Test-side spelling of each letter's spoken name (independent of the
  // production table, so a typo there is caught here).
  const spokenName = {
    'ا': 'الف',
    'ل': 'لام',
    'م': 'ميم',
    'ص': 'صاد',
    'ر': 'را',
    'ك': 'كاف',
    'ه': 'ها',
    'ي': 'يا',
    'ع': 'عين',
    'ط': 'طا',
    'س': 'سين',
    'ح': 'حا',
    'ق': 'قاف',
    'ن': 'نون',
  };

  /// Simulates STT of a correct recitation: letter names for the disjoint
  /// letters, the plain (normalized) word for everything else.
  String recitedAsHeard(String body, {String Function(String)? spell}) => [
    for (final token in tokens(body))
      MuqattaatRecitation.isMuqattaatToken(token)
          ? (spell ??
                (letters) => [
                  for (final l in letters.split('')) spokenName[l]!,
                ].join(' '))(ArabicNormalizer.normalize(token))
          : ArabicNormalizer.normalize(token),
  ].join(' ');

  group('disjoint-letter detection over the canonical corpus', () {
    test('matches exactly the 30 disjoint-letter tokens and nothing else', () {
      final found = <String>[];
      corpus.forEach((surah, verses) {
        for (final verse in verses as List) {
          final words = tokens((verse['text'] as String).replaceAll('﻿', ''));
          for (var i = 0; i < words.length; i++) {
            if (MuqattaatRecitation.isMuqattaatToken(words[i])) {
              found.add('$surah:${verse['verse']}#$i');
            }
          }
        }
      });

      // Ayah 1 of these surahs (token #4, after the basmalah) + Ash-Shura 2.
      const surahs = [2, 3, 7, 10, 11, 12, 13, 14, 15, 19, 20, 26, 27, 28];
      const more = [29, 30, 31, 32, 36, 38, 40, 41, 42, 43, 44, 45, 46, 50, 68];
      expect(found.toSet(), {
        for (final s in [...surahs, ...more]) '$s:1#4',
        '42:2#0',
      });
      expect(found, hasLength(30));
    });
  });

  group('V2RecitationEvaluator with disjoint letters', () {
    const evaluator = V2RecitationEvaluator();
    const kidsEvaluator = V2RecitationEvaluator(
      passThreshold: kKidsPassThreshold,
    );

    test('every disjoint-letter ayah passes when recited by letter name', () {
      final ayahs = <(int, int)>[
        for (final s in [2, 3, 7, 10, 11, 12, 13, 14, 15, 19, 20, 26, 27])
          (s, 1),
        for (final s in [28, 29, 30, 31, 32, 36, 38, 40, 41, 42, 43, 44])
          (s, 1),
        for (final s in [45, 46, 50, 68]) (s, 1),
        (42, 2),
      ];
      for (final (surah, ayah) in ayahs) {
        final body = ayahBody(surah, ayah);
        for (final e in [evaluator, kidsEvaluator]) {
          final result = e.evaluate(
            targetText: body,
            spokenText: recitedAsHeard(body),
          );
          expect(result.passed, isTrue, reason: '$surah:$ayah');
          expect(result.similarityScore, 1.0, reason: '$surah:$ayah');
        }
      }
    });

    test('Al-Baqarah 1 passes for «ألف لام ميم» with hamza spelling', () {
      final result = evaluator.evaluate(
        targetText: ayahBody(2, 1),
        spokenText: 'ألف لام ميم',
      );
      expect(result.passed, isTrue);
      expect(result.normalizedSpoken, result.normalizedTarget);
    });

    test('accepts joined and hamza-ended STT spellings of the names', () {
      final cases = <(int, int, String)>[
        (36, 1, 'ياسين'),
        (36, 1, 'ياء سين'),
        (40, 1, 'حاميم'),
        (40, 1, 'حاء ميم'),
        (20, 1, 'طاها'),
        (19, 1, 'كاف هاء ياء عين صاد'),
        (42, 2, 'عين سين قاف'),
      ];
      for (final (surah, ayah, spelled) in cases) {
        final body = ayahBody(surah, ayah);
        final result = evaluator.evaluate(
          targetText: body,
          spokenText: recitedAsHeard(body, spell: (_) => spelled),
        );
        expect(result.passed, isTrue, reason: '$surah:$ayah «$spelled»');
      }
    });

    test('still accepts the written form when STT returns it', () {
      final body = ayahBody(2, 1);
      final result = evaluator.evaluate(
        targetText: body,
        spokenText: ArabicNormalizer.normalize(body),
      );
      expect(result.passed, isTrue);
    });

    test('wrong or incomplete letter names do not pass', () {
      final body = ayahBody(2, 1);
      for (final spoken in ['الف لام را', 'الف لام', 'لام ميم', 'ميم']) {
        final result = evaluator.evaluate(targetText: body, spokenText: spoken);
        expect(result.passed, isFalse, reason: spoken);
      }
    });

    test('letter names never rewrite an ordinary word such as «أَلَمْ»', () {
      // Al-Fil 1 starts with an ordinary word that normalizes to «الم».
      final body = ayahBody(105, 1);
      final spoken = tokens(ArabicNormalizer.normalize(body));
      final result = evaluator.evaluate(
        targetText: body,
        spokenText: ['الف لام ميم', ...spoken.skip(1)].join(' '),
      );
      expect(result.passed, isFalse);
      expect(result.similarityScore, lessThan(1.0));
    });

    test('block review of Ash-Shura 1–2 passes when both are spelled', () {
      final target = '${ayahBody(42, 1)} ${ayahBody(42, 2)}';
      final result = evaluator.evaluate(
        targetText: target,
        spokenText: 'حا ميم عين سين قاف',
      );
      expect(result.passed, isTrue);
    });

    test('block review spanning a disjoint-letter ayah passes', () {
      final target = '${ayahBody(2, 1)} ${ayahBody(2, 2)}';
      final result = evaluator.evaluate(
        targetText: target,
        spokenText: recitedAsHeard(target),
      );
      expect(result.passed, isTrue);
      expect(result.similarityScore, 1.0);
    });
  });

  group('RecitationWordDiffer with disjoint letters', () {
    const differ = RecitationWordDiffer();

    test('letter names align to one matched word shown in written form', () {
      final body = ayahBody(2, 1);
      final diff = differ.diff(targetText: body, spokenText: 'الف لام ميم');
      expect(diff.isPerfect, isTrue);
      expect(diff.words, [
        RecitationWordDiff(
          display: tokens(body).single,
          status: RecitationWordStatus.match,
        ),
      ]);
    });

    test('a spelled opening keeps the rest of the ayah aligned', () {
      final body = ayahBody(68, 1);
      final diff = differ.diff(
        targetText: body,
        spokenText: recitedAsHeard(body),
      );
      // Standalone waqf marks have no spoken form and are never graded.
      final recitable = tokens(body).where(
        (t) =>
            RecitationWordDiffer.isRecitableWord(ArabicNormalizer.normalize(t)),
      );
      expect(diff.isPerfect, isTrue, reason: '${diff.words}');
      expect(diff.matchCount, recitable.length, reason: '${diff.words}');
      expect(diff.words.first.status, RecitationWordStatus.match);
    });

    test('wrong letter names are not counted as a match', () {
      final diff = differ.diff(
        targetText: ayahBody(2, 1),
        spokenText: 'الف لام را',
      );
      expect(diff.isPerfect, isFalse);
      expect(diff.matchCount, 0);
    });
  });
}
