import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_quiz_engine.dart';

// Keys compare letters only, so spell numbers as letters (a=0 … j=9).
String _letters(int n) =>
    n.toString().split('').map((d) => 'abcdefghij'[int.parse(d)]).join();

ListeningCorpus _corpus() => ListeningCorpus.fromTexts({
  for (var s = 1; s <= 114; s++)
    s: [
      for (var a = 1; a <= 5; a++) 'surah ${_letters(s)} ayah ${_letters(a)}',
    ],
});

List<ListeningAyahRef> _prompts(int surahId) => [
  for (var a = 1; a <= 5; a++) ListeningAyahRef(surahId, a),
];

void main() {
  const engine = ListeningQuizEngine();

  group('distractorsFor', () {
    test('uses nearest neighbours in mushaf order', () {
      expect(engine.distractorsFor(50), [49, 51, 48]);
    });

    test('stays inside 1..114 at both edges', () {
      expect(engine.distractorsFor(1), [2, 3, 4]);
      expect(engine.distractorsFor(114), [113, 112, 111]);
    });
  });

  test('which-surah options are 4 distinct surahs containing the answer', () {
    final round = engine.buildRound(
      corpus: _corpus(),
      prompts: [..._prompts(1), ..._prompts(114)],
      mode: ListeningQuizMode.whichSurah,
      random: Random(1),
    );
    expect(round, isNotEmpty);
    for (final q in round.cast<WhichSurahQuestion>()) {
      expect(q.optionSurahIds.toSet(), hasLength(4));
      expect(q.optionSurahIds, contains(q.prompt.surahId));
      expect(q.optionSurahIds.every((s) => s >= 1 && s <= 114), isTrue);
    }
  });

  test(
    'next-ayah mode never asks about the last ayah and carries canonical text',
    () {
      final corpus = _corpus();
      final round = engine.buildRound(
        corpus: corpus,
        prompts: _prompts(7),
        mode: ListeningQuizMode.nextAyah,
        random: Random(2),
      );
      expect(round, hasLength(4)); // ayah 5 is last → excluded
      for (final q in round.cast<NextAyahQuestion>()) {
        expect(q.prompt.ayahNumber, lessThan(5));
        expect(q.nextAyahText, corpus.textOf(q.answer));
      }
    },
  );

  test('same seed gives the same round; size clamps to the pool', () {
    List<ListeningQuestion> build() => engine.buildRound(
      corpus: _corpus(),
      prompts: [..._prompts(3), ..._prompts(4), ..._prompts(5)],
      mode: ListeningQuizMode.mixed,
      random: Random(42),
    );
    expect(build(), build());
    expect(build(), hasLength(ListeningQuizEngine.roundSize));
  });

  test('duplicate prompts produce one question each', () {
    final round = engine.buildRound(
      corpus: _corpus(),
      prompts: [const ListeningAyahRef(9, 1), const ListeningAyahRef(9, 1)],
      mode: ListeningQuizMode.whichSurah,
      random: Random(3),
    );
    expect(round, hasLength(1));
  });

  test('empty pool yields no questions and zero eligible prompts', () {
    final corpus = _corpus();
    expect(
      engine.buildRound(
        corpus: corpus,
        prompts: const [],
        mode: ListeningQuizMode.mixed,
        random: Random(4),
      ),
      isEmpty,
    );
    expect(engine.eligiblePromptCount(corpus, const []), 0);
  });
}
