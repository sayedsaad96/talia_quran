import 'dart:math';

import 'listening_corpus.dart';
import 'listening_question.dart';

/// Pure question builder for Listening Review. No I/O, no Flutter.
///
/// Answer keys are always derived from [ListeningCorpus]; any prompt whose
/// answer is not unique is skipped (see `canAskWhichSurah`/`canAskNextAyah`).
final class ListeningQuizEngine {
  const ListeningQuizEngine();

  static const int roundSize = 10;
  static const int minQuestions = 5;

  /// Candidates built before the cubit reorders cached audio first.
  static const int candidateSize = 30;
  static const int maxPlays = 3;
  static const int optionCount = 4;

  List<ListeningQuestion> buildRound({
    required ListeningCorpus corpus,
    required List<ListeningAyahRef> prompts,
    required ListeningQuizMode mode,
    required Random random,
    int size = roundSize,
  }) {
    final shuffled = prompts.toSet().toList()..shuffle(random);
    final questions = <ListeningQuestion>[];
    for (final prompt in shuffled) {
      if (questions.length >= size) break;
      final question = _questionFor(corpus, prompt, mode, random);
      if (question != null) questions.add(question);
    }
    return questions;
  }

  /// Prompts that can produce at least one kind of question.
  int eligiblePromptCount(
    ListeningCorpus corpus,
    List<ListeningAyahRef> prompts,
  ) => prompts
      .toSet()
      .where((p) => corpus.canAskWhichSurah(p) || corpus.canAskNextAyah(p))
      .length;

  /// The nearest surahs in mushaf order: s-1, s+1, s-2, s+2, … within 1–114.
  List<int> distractorsFor(int surahId) {
    final result = <int>[];
    for (var d = 1; result.length < optionCount - 1; d++) {
      for (final candidate in [surahId - d, surahId + d]) {
        if (candidate >= 1 &&
            candidate <= 114 &&
            result.length < optionCount - 1) {
          result.add(candidate);
        }
      }
    }
    return result;
  }

  ListeningQuestion? _questionFor(
    ListeningCorpus corpus,
    ListeningAyahRef prompt,
    ListeningQuizMode mode,
    Random random,
  ) {
    final canSurah = corpus.canAskWhichSurah(prompt);
    final canNext = corpus.canAskNextAyah(prompt);
    final useNext = switch (mode) {
      ListeningQuizMode.whichSurah => false,
      ListeningQuizMode.nextAyah => true,
      ListeningQuizMode.mixed => canNext && (!canSurah || random.nextBool()),
    };
    if (useNext) {
      if (!canNext) return null;
      final next = ListeningAyahRef(prompt.surahId, prompt.ayahNumber + 1);
      return NextAyahQuestion(prompt, nextAyahText: corpus.textOf(next)!);
    }
    if (!canSurah) return null;
    final options = [prompt.surahId, ...distractorsFor(prompt.surahId)]
      ..shuffle(random);
    return WhichSurahQuestion(
      prompt,
      optionSurahIds: List.unmodifiable(options),
    );
  }
}
