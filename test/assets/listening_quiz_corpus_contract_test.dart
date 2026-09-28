import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_quiz_engine.dart';

Map<int, List<String>> _loadTexts() {
  final decoded =
      jsonDecode(File('assets/data/quran.json').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final entry in decoded.entries)
      int.parse(entry.key): [
        for (final ayah in (entry.value as List<dynamic>))
          (ayah as Map<String, dynamic>)['text'] as String,
      ],
  };
}

void main() {
  final texts = _loadTexts();
  final corpus = ListeningCorpus.fromTexts(texts);

  // Brute-force index built independently of ListeningCorpus internals.
  final surahsByKey = <String, Set<int>>{};
  final countInSurah = <(int, String), int>{};
  texts.forEach((s, list) {
    for (final t in list) {
      final k = ListeningCorpus.normalizedKey(t);
      surahsByKey.putIfAbsent(k, () => {}).add(s);
      countInSurah.update((s, k), (c) => c + 1, ifAbsent: () => 1);
    }
  });

  test('corpus has 114 surahs', () => expect(texts.length, 114));

  test('every which-surah prompt identifies exactly one surah', () {
    var excluded = 0;
    texts.forEach((s, list) {
      for (var a = 1; a <= list.length; a++) {
        final ref = ListeningAyahRef(s, a);
        final unique =
            surahsByKey[ListeningCorpus.normalizedKey(list[a - 1])]!.length ==
            1;
        expect(corpus.canAskWhichSurah(ref), unique, reason: '$s:$a');
        if (!unique) excluded++;
      }
    });
    expect(excluded, greaterThan(0), reason: 'real corpus has shared ayahs');
  });

  test('every next-ayah prompt has exactly one continuation', () {
    var excluded = 0;
    texts.forEach((s, list) {
      for (var a = 1; a <= list.length; a++) {
        final k = ListeningCorpus.normalizedKey(list[a - 1]);
        final expected =
            a < list.length &&
            surahsByKey[k]!.length == 1 &&
            countInSurah[(s, k)] == 1;
        expect(
          corpus.canAskNextAyah(ListeningAyahRef(s, a)),
          expected,
          reason: '$s:$a',
        );
        if (!expected && a < list.length) excluded++;
      }
    });
    expect(excluded, greaterThan(0), reason: 'real corpus has refrains');
  });

  test(
    'generated next-ayah answers are ayah+1 of the same surah, verbatim',
    () {
      final prompts = [
        for (final e in texts.entries)
          for (var a = 1; a <= e.value.length; a++) ListeningAyahRef(e.key, a),
      ];
      final round = const ListeningQuizEngine().buildRound(
        corpus: corpus,
        prompts: prompts,
        mode: ListeningQuizMode.nextAyah,
        random: Random(7),
        size: 500,
      );
      expect(round, hasLength(500));
      for (final q in round.cast<NextAyahQuestion>()) {
        expect(q.answer.surahId, q.prompt.surahId);
        expect(q.answer.ayahNumber, q.prompt.ayahNumber + 1);
        expect(
          q.nextAyahText,
          texts[q.answer.surahId]![q.answer.ayahNumber - 1],
        );
      }
    },
  );
}
