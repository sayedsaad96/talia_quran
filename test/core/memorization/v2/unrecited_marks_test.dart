import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/v2/recitation_word_diff.dart';
import 'package:talia_quran/core/quran/quran_basmalah.dart';
import 'package:talia_quran/core/utils/arabic_normalizer.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_recalled_words.dart';

/// The canonical text carries written signs with no spoken form: standalone
/// waqf marks, «۞» and «۩». A correct recitation never says them, so they
/// must never count as missing. Ayah text comes from the bundled corpus.
void main() {
  late List<({int surah, int ayah, String body})> ayahs;

  setUpAll(() {
    final corpus =
        jsonDecode(File('assets/data/quran.json').readAsStringSync())
            as Map<String, dynamic>;
    final reference = ArabicNormalizer.normalize(
      (corpus['1'] as List).first['text'] as String,
    );
    ayahs = [
      for (final MapEntry(key: surah, value: verses) in corpus.entries)
        for (final verse in verses as List)
          (
            surah: int.parse(surah),
            ayah: verse['verse'] as int,
            body: QuranBasmalah.split(
              surahId: int.parse(surah),
              ayahNumber: verse['verse'] as int,
              canonicalText: verse['text'] as String,
              normalizedReference: reference,
            ).body,
          ),
    ];
  });

  List<String> tokens(String text) =>
      text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  bool isSpoken(String rawToken) => RecitationWordDiffer.isRecitableWord(
    ArabicNormalizer.normalize(rawToken),
  );

  bool hasUnrecitedSign(String body) => tokens(body).any((t) => !isSpoken(t));

  ({int surah, int ayah, String body}) firstAyahWith(String sign) =>
      ayahs.firstWhere((a) => tokens(a.body).contains(sign));

  test('the corpus does contain unrecited signs (guards the sweep)', () {
    expect(ayahs, hasLength(6236));
    expect(ayahs.where((a) => hasUnrecitedSign(a.body)), isNotEmpty);
    expect(firstAyahWith('۞'), isNotNull);
    expect(firstAyahWith('۩'), isNotNull);
  });

  test('every ayah passes with score 1.0 when recited exactly', () {
    const evaluator = V2RecitationEvaluator();
    for (final a in ayahs) {
      final spoken = tokens(
        ArabicNormalizer.normalize(a.body),
      ).where(RecitationWordDiffer.isRecitableWord).join(' ');
      final result = evaluator.evaluate(targetText: a.body, spokenText: spoken);
      expect(result.passed, isTrue, reason: '${a.surah}:${a.ayah}');
      expect(result.similarityScore, 1.0, reason: '${a.surah}:${a.ayah}');
    }
  });

  test('every ayah diffs as perfect when recited exactly', () {
    const differ = RecitationWordDiffer();
    for (final a in ayahs.where((a) => hasUnrecitedSign(a.body))) {
      final raw = tokens(a.body);
      final spoken = [
        for (final t in raw)
          if (RecitationWordDiffer.isRecitableWord(
            ArabicNormalizer.normalize(t),
          ))
            ArabicNormalizer.normalize(t),
      ].join(' ');
      final diff = differ.diff(targetText: a.body, spokenText: spoken);
      final where = '${a.surah}:${a.ayah}';
      expect(diff.isPerfect, isTrue, reason: '$where ${diff.words}');
      // Every written token keeps its place, in order, as written.
      expect(diff.words.map((w) => w.display).toList(), raw, reason: where);
    }
  });

  test('«۞» is shown as not recited and never as missing', () {
    final a = firstAyahWith('۞');
    final diff = const RecitationWordDiffer().diff(
      targetText: a.body,
      spokenText: '',
    );
    final sign = diff.words.firstWhere((w) => w.display == '۞');
    expect(sign.status, RecitationWordStatus.notRecited);
    expect(diff.missingCount, tokens(a.body).where(isSpoken).length);
  });

  test('kids flags stay one per written token, signs unflagged', () {
    final a = firstAyahWith('۞');
    final raw = tokens(a.body);
    final spoken = tokens(
      ArabicNormalizer.normalize(a.body),
    ).where(RecitationWordDiffer.isRecitableWord).join(' ');
    final flags = kidsRecalledWords(targetText: a.body, spokenText: spoken);
    expect(flags, hasLength(raw.length));
    for (var i = 0; i < raw.length; i++) {
      expect(flags[i], isSpoken(raw[i]), reason: raw[i]);
    }
  });
}
