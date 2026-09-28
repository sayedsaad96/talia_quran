# Listening Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an adult "مراجعة بالسماع" practice mode: the user hears an ayah they memorized and either names its surah or recites the next ayah; mistakes become a "weak links" list that opens normal review sessions.

**Architecture:** A pure-Dart engine (`lib/core/memorization/listening/`) builds rounds from a corpus index that excludes every question whose answer is not unique. A data-layer source loads adult review records + the frozen corpus. A Cubit drives rounds through two thin adapters (audio, speech capture) so it is unit-testable, and writes only owner-scoped local stats. Nothing touches SRS, review records, XP, or the V2 session engine.

**Tech Stack:** Flutter, flutter_bloc (Cubit), dartz `Either`, get_it, go_router, just_audio via `AudioCacheService`, speech_to_text + permission_handler, SharedPreferences, mocktail, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-28-listening-review-design.md`

## Global Constraints

- No new religious text. Ayah text comes only from `QuranRepository` (backed by `assets/data/quran.json`); displayed text is the canonical `Ayah.text`, never normalized or edited.
- `ArabicNormalizer.normalize` is used for comparison keys only, never for display.
- Read-only over review records: no call to `saveReviewRecord`, the review outcome committer, XP, streak, or cloud sync.
- Adult path only in v1: route guarded by `MemorizationRouteGuard.adultOnlyRedirect()`; records read with `ReviewRecordReadScope.adult`.
- Round size 10; a round needs at least 5 questions, otherwise show the "not enough" state.
- Max 3 plays per question.
- Stats key must be owner-scoped: `listening_review_stats_v1_<ownerId>` via `RecordOwnerProvider.currentOwnerId`.
- New l10n keys go into both `lib/core/l10n/app_ar.arb` and `lib/core/l10n/app_en.arb`, then `flutter gen-l10n`.
- Lints: `unawaited_futures`, `avoid_print` (use `TaliaLogger`), `prefer_final_locals`.
- Format only the files you edit (`dart format <file>`), never whole directories — the tree contains the owner's uncommitted work.
- Commit only the files of the task (`git add <paths>`), never `git add -A`.

## Decisions taken while planning

| Question | Decision | Reason |
|---|---|---|
| "Next ayah" when the prompt ayah's text also exists in another surah | Excluded too (in addition to the spec's intra-surah repeat rule), and the question shows the surah name. | Hearing only the audio, the user cannot know which surah's continuation is meant. Tightens the P0 guard. |
| Weak-link target | Opens a review session for the exact ayah the user missed (prompt ayah for "which surah", ayah N+1 for "next ayah"), with `LearningOrigin.review`. | More precise than "the surah"; reuses the existing V2 session route and origin enum (no new enum value to serialize). |
| "Prefer cached audio" without a connectivity package | Engine builds up to 30 candidate questions; the cubit moves cached ones first, then takes 10. Uncached questions that fail to play are skipped (unscored). | The project has no connectivity dependency; play failure is the reliable offline signal. |
| STT empty result | First empty result → user may retry; second empty result → switch to self-grade for that question. | Matches the spec's "retry once, then fallback". |

## Review Focus

1. **Surah 1 / surah 114 distractors** — options must still be 4 distinct valid surahs (1→2,3,4; 114→113,112,111). Pinned in Task 2.
2. **Pool containing kids or unstarted records** — only adult-scope records with `totalReviews > 0` become prompts. Pinned in Task 3.
3. **Audio fails mid-round (offline)** — the question is skipped, not counted wrong, and the round still finishes with a correct score denominator. Pinned in Task 5.
4. **Account switch** — stats written by user A are invisible to user B. Pinned in Task 4.
5. **Answer tapped twice / answer after reveal** — second tap is ignored; the recorded outcome never changes. Pinned in Task 5.

---

### Task 1: Question models, round result, and corpus ambiguity index

**Files:**
- Create: `lib/core/memorization/listening/listening_question.dart`
- Create: `lib/core/memorization/listening/listening_round_result.dart`
- Create: `lib/core/memorization/listening/listening_corpus.dart`
- Test: `test/core/memorization/listening/listening_corpus_test.dart`
- Test: `test/core/memorization/listening/listening_round_result_test.dart`

**Interfaces:**
- Consumes: `ArabicNormalizer.normalize(String)` from `lib/core/utils/arabic_normalizer.dart`.
- Produces:
  - `enum ListeningQuizMode { whichSurah, nextAyah, mixed }`
  - `ListeningAyahRef(int surahId, int ayahNumber)` (Equatable)
  - `sealed class ListeningQuestion { ListeningAyahRef prompt; }`
  - `WhichSurahQuestion(prompt, {required List<int> optionSurahIds})`
  - `NextAyahQuestion(prompt, {required String nextAyahText})` with `ListeningAyahRef get answer`
  - `enum ListeningOutcome { correct, hesitant, wrong, skipped }`
  - `ListeningAnswer(ListeningQuestion question, ListeningOutcome outcome)` with `ListeningAyahRef get reviewTarget`
  - `ListeningRoundResult(List<ListeningAnswer> answers)` with `int scored`, `int correct`, `List<ListeningAyahRef> weakLinks`
  - `ListeningCorpus.fromTexts(Map<int, List<String>>)`, `int ayahCount(int)`, `String? textOf(ListeningAyahRef)`, `bool canAskWhichSurah(ListeningAyahRef)`, `bool canAskNextAyah(ListeningAyahRef)`, `static String normalizedKey(String)`

- [ ] **Step 1: Write the failing corpus test**

`test/core/memorization/listening/listening_corpus_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';

// Synthetic texts: the tests exercise the ambiguity rules, not real ayahs.
ListeningCorpus _corpus() => ListeningCorpus.fromTexts({
  1: ['alpha one', 'alpha two', 'alpha three'],
  2: ['beta one', 'shared line', 'beta three', 'refrain', 'beta five', 'refrain', 'beta seven'],
  3: ['gamma one', 'shared line', 'gamma three'],
});

void main() {
  group('canAskWhichSurah', () {
    test('allows an ayah whose text is unique across surahs', () {
      expect(_corpus().canAskWhichSurah(const ListeningAyahRef(1, 2)), isTrue);
    });

    test('rejects an ayah whose text also appears in another surah', () {
      final corpus = _corpus();
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(2, 2)), isFalse);
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(3, 2)), isFalse);
    });

    test('allows an intra-surah refrain (the surah is still unique)', () {
      expect(_corpus().canAskWhichSurah(const ListeningAyahRef(2, 4)), isTrue);
    });

    test('rejects refs outside the corpus', () {
      final corpus = _corpus();
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(9, 1)), isFalse);
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(1, 0)), isFalse);
      expect(corpus.canAskWhichSurah(const ListeningAyahRef(1, 4)), isFalse);
    });
  });

  group('canAskNextAyah', () {
    test('allows a unique ayah that has a successor in the same surah', () {
      expect(_corpus().canAskNextAyah(const ListeningAyahRef(1, 1)), isTrue);
    });

    test('rejects the last ayah of a surah', () {
      expect(_corpus().canAskNextAyah(const ListeningAyahRef(1, 3)), isFalse);
    });

    test('rejects an ayah repeated inside its surah', () {
      final corpus = _corpus();
      expect(corpus.canAskNextAyah(const ListeningAyahRef(2, 4)), isFalse);
      expect(corpus.canAskNextAyah(const ListeningAyahRef(2, 6)), isFalse);
    });

    test('rejects an ayah whose text also appears in another surah', () {
      expect(_corpus().canAskNextAyah(const ListeningAyahRef(2, 2)), isFalse);
    });
  });

  test('normalizedKey ignores diacritics, BOM and extra whitespace', () {
    expect(
      ListeningCorpus.normalizedKey('﻿بِسْمِ  ٱللَّهِ '),
      ListeningCorpus.normalizedKey('بسم الله'),
    );
  });

  test('textOf returns the canonical text unchanged', () {
    expect(_corpus().textOf(const ListeningAyahRef(2, 3)), 'beta three');
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/memorization/listening/listening_corpus_test.dart`
Expected: FAIL — `listening_corpus.dart` / `listening_question.dart` not found.

- [ ] **Step 3: Implement the models**

`lib/core/memorization/listening/listening_question.dart`:

```dart
import 'package:equatable/equatable.dart';

/// Which kind of question a listening round asks.
enum ListeningQuizMode { whichSurah, nextAyah, mixed }

/// A (surah, ayah) pair inside the listening quiz.
final class ListeningAyahRef extends Equatable {
  const ListeningAyahRef(this.surahId, this.ayahNumber);

  final int surahId;
  final int ayahNumber;

  @override
  List<Object?> get props => [surahId, ayahNumber];
}

/// One question of a listening round. The [prompt] ayah's audio is played.
sealed class ListeningQuestion extends Equatable {
  const ListeningQuestion(this.prompt);

  final ListeningAyahRef prompt;
}

/// "Which surah is this ayah from?" — exactly one option equals
/// `prompt.surahId`; the list is already shuffled.
final class WhichSurahQuestion extends ListeningQuestion {
  const WhichSurahQuestion(super.prompt, {required this.optionSurahIds});

  final List<int> optionSurahIds;

  @override
  List<Object?> get props => [prompt, optionSurahIds];
}

/// "Recite the ayah after this one." [nextAyahText] is the canonical,
/// unmodified text of `prompt.ayahNumber + 1` in the same surah.
final class NextAyahQuestion extends ListeningQuestion {
  const NextAyahQuestion(super.prompt, {required this.nextAyahText});

  final String nextAyahText;

  ListeningAyahRef get answer =>
      ListeningAyahRef(prompt.surahId, prompt.ayahNumber + 1);

  @override
  List<Object?> get props => [prompt, nextAyahText];
}
```

`lib/core/memorization/listening/listening_round_result.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'listening_question.dart';

enum ListeningOutcome { correct, hesitant, wrong, skipped }

final class ListeningAnswer extends Equatable {
  const ListeningAnswer(this.question, this.outcome);

  final ListeningQuestion question;
  final ListeningOutcome outcome;

  /// The ayah the learner should review when this answer is weak: the heard
  /// ayah for "which surah", the missed continuation for "next ayah".
  ListeningAyahRef get reviewTarget => switch (question) {
    WhichSurahQuestion(:final prompt) => prompt,
    final NextAyahQuestion q => q.answer,
  };

  bool get isWeak =>
      outcome == ListeningOutcome.wrong || outcome == ListeningOutcome.hesitant;

  @override
  List<Object?> get props => [question, outcome];
}

final class ListeningRoundResult extends Equatable {
  const ListeningRoundResult(this.answers);

  final List<ListeningAnswer> answers;

  /// Answers that count toward the score (skipped audio failures do not).
  int get scored =>
      answers.where((a) => a.outcome != ListeningOutcome.skipped).length;

  int get correct =>
      answers.where((a) => a.outcome == ListeningOutcome.correct).length;

  /// Distinct review targets of weak answers, in round order.
  List<ListeningAyahRef> get weakLinks {
    final seen = <ListeningAyahRef>{};
    return [
      for (final answer in answers)
        if (answer.isWeak && seen.add(answer.reviewTarget)) answer.reviewTarget,
    ];
  }

  @override
  List<Object?> get props => [answers];
}
```

`lib/core/memorization/listening/listening_corpus.dart`:

```dart
import '../../utils/arabic_normalizer.dart';
import 'listening_question.dart';

/// Frozen Quran texts plus the ambiguity indexes the listening quiz needs.
///
/// Normalized keys are comparison-only; [textOf] always returns the
/// canonical text exactly as loaded.
final class ListeningCorpus {
  ListeningCorpus._(this._texts, this._crossSurahDuplicates, this._repeats);

  /// [ayahTextsBySurah] maps surah id → canonical ayah texts in order
  /// (index 0 is ayah 1).
  factory ListeningCorpus.fromTexts(Map<int, List<String>> ayahTextsBySurah) {
    final surahsByKey = <String, Set<int>>{};
    final repeats = <int, Set<String>>{};
    ayahTextsBySurah.forEach((surahId, texts) {
      final seen = <String>{};
      for (final text in texts) {
        final key = normalizedKey(text);
        surahsByKey.putIfAbsent(key, () => <int>{}).add(surahId);
        if (!seen.add(key)) repeats.putIfAbsent(surahId, () => <String>{}).add(key);
      }
    });
    return ListeningCorpus._(
      {
        for (final entry in ayahTextsBySurah.entries)
          entry.key: List<String>.unmodifiable(entry.value),
      },
      {
        for (final entry in surahsByKey.entries)
          if (entry.value.length > 1) entry.key,
      },
      repeats,
    );
  }

  static String normalizedKey(String text) => ArabicNormalizer.normalize(
    text.replaceAll('﻿', ''),
  ).replaceAll(RegExp(r'\s+'), ' ').trim();

  final Map<int, List<String>> _texts;
  final Set<String> _crossSurahDuplicates;
  final Map<int, Set<String>> _repeats;

  int ayahCount(int surahId) => _texts[surahId]?.length ?? 0;

  String? textOf(ListeningAyahRef ref) {
    final texts = _texts[ref.surahId];
    if (texts == null || ref.ayahNumber < 1 || ref.ayahNumber > texts.length) {
      return null;
    }
    return texts[ref.ayahNumber - 1];
  }

  bool _isCrossSurahDuplicate(String text) =>
      _crossSurahDuplicates.contains(normalizedKey(text));

  /// True when the heard ayah identifies exactly one surah.
  bool canAskWhichSurah(ListeningAyahRef ref) {
    final text = textOf(ref);
    return text != null && !_isCrossSurahDuplicate(text);
  }

  /// True when "the next ayah" is unique: not the last ayah, not repeated
  /// inside its surah, and not shared with another surah.
  bool canAskNextAyah(ListeningAyahRef ref) {
    final text = textOf(ref);
    if (text == null || ref.ayahNumber >= ayahCount(ref.surahId)) return false;
    if (_isCrossSurahDuplicate(text)) return false;
    return !(_repeats[ref.surahId]?.contains(normalizedKey(text)) ?? false);
  }
}
```

- [ ] **Step 4: Write the round-result test**

`test/core/memorization/listening/listening_round_result_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_round_result.dart';

void main() {
  const surahQ = WhichSurahQuestion(ListeningAyahRef(2, 5), optionSurahIds: [1, 2, 3, 4]);
  const nextQ = NextAyahQuestion(ListeningAyahRef(3, 7), nextAyahText: 'x');

  test('skipped answers do not count toward the score', () {
    const result = ListeningRoundResult([
      ListeningAnswer(surahQ, ListeningOutcome.correct),
      ListeningAnswer(nextQ, ListeningOutcome.skipped),
    ]);
    expect(result.scored, 1);
    expect(result.correct, 1);
  });

  test('weak links point at the heard ayah or the missed continuation', () {
    const result = ListeningRoundResult([
      ListeningAnswer(surahQ, ListeningOutcome.wrong),
      ListeningAnswer(nextQ, ListeningOutcome.hesitant),
      ListeningAnswer(surahQ, ListeningOutcome.wrong),
    ]);
    expect(result.weakLinks, const [ListeningAyahRef(2, 5), ListeningAyahRef(3, 8)]);
  });

  test('correct and skipped answers are never weak', () {
    const result = ListeningRoundResult([
      ListeningAnswer(surahQ, ListeningOutcome.correct),
      ListeningAnswer(nextQ, ListeningOutcome.skipped),
    ]);
    expect(result.weakLinks, isEmpty);
  });
}
```

- [ ] **Step 5: Run both tests**

Run: `flutter test test/core/memorization/listening/`
Expected: PASS (all tests).

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib/core/memorization/listening test/core/memorization/listening
flutter analyze lib/core/memorization/listening test/core/memorization/listening
git add lib/core/memorization/listening test/core/memorization/listening
git commit -m "feat(listening): add question models and corpus ambiguity index"
```

---

### Task 2: Quiz engine + full-corpus contract test

**Files:**
- Create: `lib/core/memorization/listening/listening_quiz_engine.dart`
- Test: `test/core/memorization/listening/listening_quiz_engine_test.dart`
- Test: `test/assets/listening_quiz_corpus_contract_test.dart`

**Interfaces:**
- Consumes: Task 1 types.
- Produces:
  - `ListeningQuizEngine()` (const), constants `roundSize = 10`, `minQuestions = 5`, `candidateSize = 30`, `maxPlays = 3`, `optionCount = 4`
  - `List<ListeningQuestion> buildRound({required ListeningCorpus corpus, required List<ListeningAyahRef> prompts, required ListeningQuizMode mode, required Random random, int size = roundSize})`
  - `List<int> distractorsFor(int surahId)`
  - `int eligiblePromptCount(ListeningCorpus corpus, List<ListeningAyahRef> prompts)`

- [ ] **Step 1: Write the failing engine test**

`test/core/memorization/listening/listening_quiz_engine_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_quiz_engine.dart';

ListeningCorpus _corpus() => ListeningCorpus.fromTexts({
  for (var s = 1; s <= 114; s++)
    s: [for (var a = 1; a <= 5; a++) 'surah $s ayah $a'],
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

  test('next-ayah mode never asks about the last ayah and carries canonical text', () {
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
  });

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
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/memorization/listening/listening_quiz_engine_test.dart`
Expected: FAIL — `listening_quiz_engine.dart` not found.

- [ ] **Step 3: Implement the engine**

`lib/core/memorization/listening/listening_quiz_engine.dart`:

```dart
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
```

- [ ] **Step 4: Run the engine test**

Run: `flutter test test/core/memorization/listening/listening_quiz_engine_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the full-corpus contract test**

`test/assets/listening_quiz_corpus_contract_test.dart` (reads the bundled file the same way `corpus_integrity_test.dart` does):

```dart
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
            surahsByKey[ListeningCorpus.normalizedKey(list[a - 1])]!.length == 1;
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
        final expected = a < list.length &&
            surahsByKey[k]!.length == 1 &&
            countInSurah[(s, k)] == 1;
        expect(corpus.canAskNextAyah(ListeningAyahRef(s, a)), expected,
            reason: '$s:$a');
        if (!expected && a < list.length) excluded++;
      }
    });
    expect(excluded, greaterThan(0), reason: 'real corpus has refrains');
  });

  test('generated next-ayah answers are ayah+1 of the same surah, verbatim', () {
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
    for (final q in round.cast<NextAyahQuestion>()) {
      expect(q.answer.surahId, q.prompt.surahId);
      expect(q.answer.ayahNumber, q.prompt.ayahNumber + 1);
      expect(q.nextAyahText, texts[q.answer.surahId]![q.answer.ayahNumber - 1]);
    }
  });
}
```

- [ ] **Step 6: Run the contract test**

Run: `flutter test test/assets/listening_quiz_corpus_contract_test.dart`
Expected: PASS. If an `excluded > 0` expectation fails, do **not** edit the corpus or the test data — stop and report: it means the normalizer or the file differs from assumptions (P0 investigation).

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib/core/memorization/listening/listening_quiz_engine.dart test/core/memorization/listening/listening_quiz_engine_test.dart test/assets/listening_quiz_corpus_contract_test.dart
flutter analyze lib/core/memorization/listening test/core/memorization/listening test/assets/listening_quiz_corpus_contract_test.dart
git add lib/core/memorization/listening/listening_quiz_engine.dart test/core/memorization/listening/listening_quiz_engine_test.dart test/assets/listening_quiz_corpus_contract_test.dart
git commit -m "feat(listening): add quiz engine with full-corpus answer contract"
```

---

### Task 3: Quiz material source (records + corpus loader)

**Files:**
- Create: `lib/features/memorization_plus/data/listening/listening_quiz_source.dart`
- Test: `test/features/memorization_plus/data/listening/listening_quiz_source_test.dart`

**Interfaces:**
- Consumes: `MemorizationPlusRepository.getAllReviewRecords({ReviewRecordReadScope scope})`, `QuranRepository.getSurahs()`, `QuranRepository.getSurahDetail(int)`, `ReviewRecordFilters.isStarted(AyahReviewRecord)`, Task 1 `ListeningCorpus`, `ListeningAyahRef`.
- Produces:
  - `ListeningQuizMaterial({required ListeningCorpus corpus, required List<ListeningAyahRef> prompts, required Map<int, Surah> surahs})`
  - `ListeningQuizSource(MemorizationPlusRepository, QuranRepository)` with `Future<Either<Failure, ListeningQuizMaterial>> load()`

- [ ] **Step 1: Write the failing test**

`test/features/memorization_plus/data/listening/listening_quiz_source_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_quiz_source.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _MockMemRepo extends Mock implements MemorizationPlusRepository {}

class _MockQuranRepo extends Mock implements QuranRepository {}

AyahReviewRecord _record(int s, int a, {int reviews = 2}) => AyahReviewRecord(
  surahId: s,
  ayahNumber: a,
  strengthLevel: 3,
  intervalDays: 2,
  lastReviewedAt: DateTime(2026, 9, 1),
  nextReviewDate: DateTime(2026, 9, 3),
  totalReviews: reviews,
  lastRating: PerformanceRating.average,
);

Surah _surah(int id) => Surah(
  id: id,
  nameAr: 'سورة $id',
  nameEn: 'Surah $id',
  ayahCount: 2,
  juz: 1,
  type: 'meccan',
  page: 1,
);

SurahDetail _detail(int id) => SurahDetail(
  surah: _surah(id),
  ayahs: [
    for (var a = 1; a <= 2; a++)
      Ayah(number: id * 10 + a, surahId: id, text: 't$id-$a', numberInSurah: a),
  ],
);

void main() {
  late _MockMemRepo mem;
  late _MockQuranRepo quran;

  setUpAll(() => registerFallbackValue(ReviewRecordReadScope.adult));

  setUp(() {
    mem = _MockMemRepo();
    quran = _MockQuranRepo();
    when(() => quran.getSurahs()).thenAnswer(
      (_) async => Right([for (var s = 1; s <= 114; s++) _surah(s)]),
    );
    when(() => quran.getSurahDetail(any())).thenAnswer(
      (inv) async => Right(_detail(inv.positionalArguments.first as int)),
    );
  });

  test('reads adult scope and keeps only started records as prompts', () async {
    when(() => mem.getAllReviewRecords(scope: any(named: 'scope'))).thenAnswer(
      (_) async => Right([_record(1, 1), _record(2, 2, reviews: 0), _record(1, 1)]),
    );

    final result = await ListeningQuizSource(mem, quran).load();
    final material = result.getOrElse(() => throw StateError('expected Right'));

    verify(() => mem.getAllReviewRecords(scope: ReviewRecordReadScope.adult)).called(1);
    expect(material.prompts, const [ListeningAyahRef(1, 1)]);
    expect(material.corpus.textOf(const ListeningAyahRef(2, 2)), 't2-2');
    expect(material.surahs[114]!.nameEn, 'Surah 114');
  });

  test('fails closed when records cannot be read', () async {
    when(() => mem.getAllReviewRecords(scope: any(named: 'scope')))
        .thenAnswer((_) async => const Left(CacheFailure()));
    expect((await ListeningQuizSource(mem, quran).load()).isLeft(), isTrue);
  });

  test('fails closed when any surah detail cannot be read', () async {
    when(() => mem.getAllReviewRecords(scope: any(named: 'scope')))
        .thenAnswer((_) async => Right([_record(1, 1)]));
    when(() => quran.getSurahDetail(57))
        .thenAnswer((_) async => const Left(ParseFailure()));
    expect((await ListeningQuizSource(mem, quran).load()).isLeft(), isTrue);
  });

  test('fails closed when the surah list is incomplete', () async {
    when(() => mem.getAllReviewRecords(scope: any(named: 'scope')))
        .thenAnswer((_) async => Right([_record(1, 1)]));
    when(() => quran.getSurahs()).thenAnswer((_) async => Right([_surah(1)]));
    expect((await ListeningQuizSource(mem, quran).load()).isLeft(), isTrue);
  });
}
```

Note: if `PerformanceRating` or `AyahReviewRecord` are not exported from `memorization_entities.dart`, import `package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart` instead (the fixture in `test/core/memorization/global_daily_plan_review_queue_test.dart` shows the working import).

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/memorization_plus/data/listening/listening_quiz_source_test.dart`
Expected: FAIL — `listening_quiz_source.dart` not found.

- [ ] **Step 3: Implement the source**

`lib/features/memorization_plus/data/listening/listening_quiz_source.dart`:

```dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/memorization/listening/listening_corpus.dart';
import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/review_record_filters.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

/// Everything one listening round needs, loaded once per page visit.
final class ListeningQuizMaterial {
  const ListeningQuizMaterial({
    required this.corpus,
    required this.prompts,
    required this.surahs,
  });

  final ListeningCorpus corpus;

  /// Distinct adult ayahs the learner has reviewed at least once.
  final List<ListeningAyahRef> prompts;

  final Map<int, Surah> surahs;
}

/// Loads adult review records and the frozen Quran corpus. Read-only: never
/// writes review records. Any read failure fails the whole load (no partial
/// corpus → no guessed questions).
class ListeningQuizSource {
  ListeningQuizSource(this._memorization, this._quran);

  final MemorizationPlusRepository _memorization;
  final QuranRepository _quran;

  Future<Either<Failure, ListeningQuizMaterial>> load() async {
    Failure? failure;
    var records = const <AyahReviewRecord>[];
    (await _memorization.getAllReviewRecords(
      scope: ReviewRecordReadScope.adult,
    )).fold((f) => failure = f, (r) => records = r);
    if (failure != null) return Left(failure!);

    var surahList = const <Surah>[];
    (await _quran.getSurahs()).fold((f) => failure = f, (s) => surahList = s);
    if (failure != null) return Left(failure!);
    if (surahList.length != 114) return const Left(ParseFailure());

    final texts = <int, List<String>>{};
    for (final surah in surahList) {
      (await _quran.getSurahDetail(surah.id)).fold(
        (f) => failure = f,
        (detail) => texts[surah.id] = [
          for (final ayah in detail.ayahs) ayah.text,
        ],
      );
      if (failure != null) return Left(failure!);
    }

    final prompts = <ListeningAyahRef>{
      for (final record in records)
        if (ReviewRecordFilters.isStarted(record))
          ListeningAyahRef(record.surahId, record.ayahNumber),
    }.toList();

    return Right(
      ListeningQuizMaterial(
        corpus: ListeningCorpus.fromTexts(texts),
        prompts: prompts,
        surahs: {for (final s in surahList) s.id: s},
      ),
    );
  }
}
```

Check `ReviewRecordFilters` import path with `grep -rn "class ReviewRecordFilters" lib` and `AyahReviewRecord` export before running; fix only the import lines if they differ.

- [ ] **Step 4: Run the test**

Run: `flutter test test/features/memorization_plus/data/listening/listening_quiz_source_test.dart`
Expected: PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib/features/memorization_plus/data/listening test/features/memorization_plus/data/listening
flutter analyze lib/features/memorization_plus/data/listening test/features/memorization_plus/data/listening
git add lib/features/memorization_plus/data/listening test/features/memorization_plus/data/listening
git commit -m "feat(listening): load adult prompts and frozen corpus for listening review"
```

---

### Task 4: Owner-scoped stats store + audio and speech adapters

**Files:**
- Create: `lib/features/memorization_plus/data/listening/listening_review_stats_store.dart`
- Create: `lib/features/memorization_plus/data/listening/listening_audio.dart`
- Create: `lib/features/memorization_plus/data/listening/listening_recitation_capture.dart`
- Test: `test/features/memorization_plus/data/listening/listening_review_stats_store_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences`, `RecordOwnerProvider` / `FixedRecordOwnerProvider` (`lib/core/identity/record_owner_provider.dart`), `AudioCacheService`, `SpeechToText`, `Permission.microphone`, `kArabicSpeechLocaleId` (`lib/core/constants/speech_constants.dart`), Task 1 `ListeningRoundResult`, `ListeningAyahRef`.
- Produces:
  - `ListeningReviewStats({int? lastCorrect, int? lastScored, int? bestPercent})`, `static const empty`, `bool get hasPlayed`
  - `ListeningReviewStatsStore(SharedPreferences, RecordOwnerProvider)`: `ListeningReviewStats read()`, `Future<void> record(ListeningRoundResult)`
  - `abstract interface class ListeningAudio { Future<bool> isCached(ListeningAyahRef); Future<bool> play(ListeningAyahRef); Future<void> stop(); Future<void> dispose(); }` and `JustAudioListeningAudio(AudioCacheService, [AudioPlayer?])`
  - `enum ListeningCaptureReadiness { ready, permissionDenied, unavailable }`
  - `abstract interface class ListeningRecitationCapture { Future<ListeningCaptureReadiness> prepare(); Future<void> start(void Function(String words) onWords); Future<String> stop(); Future<void> cancel(); }` and `SpeechToTextListeningCapture([SpeechToText?])`

- [ ] **Step 1: Write the failing stats-store test**

`test/features/memorization_plus/data/listening/listening_review_stats_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_round_result.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_review_stats_store.dart';

const _q = WhichSurahQuestion(ListeningAyahRef(1, 1), optionSurahIds: [1, 2, 3, 4]);

ListeningRoundResult _result(int correct, int wrong) => ListeningRoundResult([
  for (var i = 0; i < correct; i++) const ListeningAnswer(_q, ListeningOutcome.correct),
  for (var i = 0; i < wrong; i++) const ListeningAnswer(_q, ListeningOutcome.wrong),
]);

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('starts empty', () {
    final store = ListeningReviewStatsStore(prefs, const FixedRecordOwnerProvider('a'));
    expect(store.read(), ListeningReviewStats.empty);
    expect(store.read().hasPlayed, isFalse);
  });

  test('records last round and keeps the best percent', () async {
    final store = ListeningReviewStatsStore(prefs, const FixedRecordOwnerProvider('a'));
    await store.record(_result(8, 2));
    await store.record(_result(5, 5));
    expect(
      store.read(),
      const ListeningReviewStats(lastCorrect: 5, lastScored: 10, bestPercent: 80),
    );
  });

  test('a round with nothing scored is not recorded', () async {
    final store = ListeningReviewStatsStore(prefs, const FixedRecordOwnerProvider('a'));
    await store.record(const ListeningRoundResult([]));
    expect(store.read().hasPlayed, isFalse);
  });

  test('stats are isolated per account', () async {
    await ListeningReviewStatsStore(prefs, const FixedRecordOwnerProvider('a'))
        .record(_result(9, 1));
    final other = ListeningReviewStatsStore(prefs, const FixedRecordOwnerProvider('b'));
    expect(other.read().hasPlayed, isFalse);
  });

  test('corrupt stored JSON reads as empty', () async {
    await prefs.setString('listening_review_stats_v1_a', '{not json');
    final store = ListeningReviewStatsStore(prefs, const FixedRecordOwnerProvider('a'));
    expect(store.read(), ListeningReviewStats.empty);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/memorization_plus/data/listening/listening_review_stats_store_test.dart`
Expected: FAIL — store not found.

- [ ] **Step 3: Implement the stats store**

`lib/features/memorization_plus/data/listening/listening_review_stats_store.dart`:

```dart
import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/memorization/listening/listening_round_result.dart';

final class ListeningReviewStats extends Equatable {
  const ListeningReviewStats({
    this.lastCorrect,
    this.lastScored,
    this.bestPercent,
  });

  static const empty = ListeningReviewStats();

  final int? lastCorrect;
  final int? lastScored;
  final int? bestPercent;

  bool get hasPlayed => lastScored != null;

  @override
  List<Object?> get props => [lastCorrect, lastScored, bestPercent];
}

/// Local, owner-scoped practice stats. Not progress of record: never synced
/// and never read by SRS.
class ListeningReviewStatsStore {
  ListeningReviewStatsStore(this._prefs, this._owner);

  static const _keyPrefix = 'listening_review_stats_v1_';

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  String get _key => '$_keyPrefix${_owner.currentOwnerId}';

  ListeningReviewStats read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return ListeningReviewStats.empty;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ListeningReviewStats(
        lastCorrect: map['lastCorrect'] as int?,
        lastScored: map['lastScored'] as int?,
        bestPercent: map['bestPercent'] as int?,
      );
    } catch (_) {
      return ListeningReviewStats.empty;
    }
  }

  Future<void> record(ListeningRoundResult result) async {
    if (result.scored == 0) return;
    final percent = (result.correct * 100 / result.scored).round();
    final best = max(percent, read().bestPercent ?? 0);
    await _prefs.setString(
      _key,
      jsonEncode({
        'lastCorrect': result.correct,
        'lastScored': result.scored,
        'bestPercent': best,
      }),
    );
  }
}
```

- [ ] **Step 4: Run the test**

Run: `flutter test test/features/memorization_plus/data/listening/listening_review_stats_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Implement the audio adapter** (thin platform wrapper; exercised through the cubit's fake in Task 5)

`lib/features/memorization_plus/data/listening/listening_audio.dart`:

```dart
import 'package:just_audio/just_audio.dart';

import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/utils/talia_logger.dart';

/// Audio seam for Listening Review so the cubit can be unit-tested.
abstract interface class ListeningAudio {
  Future<bool> isCached(ListeningAyahRef ref);

  /// Plays the ayah once. Completes when playback ends; returns false when
  /// the ayah could not be played (e.g. offline and not cached).
  Future<bool> play(ListeningAyahRef ref);

  Future<void> stop();

  Future<void> dispose();
}

class JustAudioListeningAudio implements ListeningAudio {
  JustAudioListeningAudio(this._cache, [AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioCacheService _cache;
  final AudioPlayer _player;

  @override
  Future<bool> isCached(ListeningAyahRef ref) async =>
      await _cache.getCachedFilePath(ref.surahId, ref.ayahNumber) != null;

  @override
  Future<bool> play(ListeningAyahRef ref) async {
    try {
      final source = await _cache.getAudioSource(ref.surahId, ref.ayahNumber);
      // just_audio's play() completes when playback stops or completes.
      await AudioCacheService.playFromSource(_player, source);
      await _player.pause();
      return true;
    } catch (e, stack) {
      TaliaLogger.w('Listening review: ayah audio unavailable', e, stack);
      return false;
    }
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
```

Check the logger import with `grep -rn "class TaliaLogger" lib` and that `TaliaLogger.w(message, error, stack)` matches its signature (it is used that way in `memorization_session_cubit.dart`).

- [ ] **Step 6: Implement the speech adapter**

`lib/features/memorization_plus/data/listening/listening_recitation_capture.dart`:

```dart
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/constants/speech_constants.dart';
import '../../../../core/utils/talia_logger.dart';

enum ListeningCaptureReadiness { ready, permissionDenied, unavailable }

/// Speech seam for Listening Review so the cubit can be unit-tested.
abstract interface class ListeningRecitationCapture {
  Future<ListeningCaptureReadiness> prepare();

  Future<void> start(void Function(String words) onWords);

  /// Stops listening and returns the recognized words ('' when none).
  Future<String> stop();

  Future<void> cancel();
}

class SpeechToTextListeningCapture implements ListeningRecitationCapture {
  SpeechToTextListeningCapture([SpeechToText? speech])
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  String _words = '';

  @override
  Future<ListeningCaptureReadiness> prepare() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) status = await Permission.microphone.request();
    if (!status.isGranted) return ListeningCaptureReadiness.permissionDenied;
    if (!_initialized) {
      try {
        _initialized = await _speech.initialize();
      } catch (e, stack) {
        TaliaLogger.w('Listening review: speech unavailable', e, stack);
        _initialized = false;
      }
    }
    return _initialized
        ? ListeningCaptureReadiness.ready
        : ListeningCaptureReadiness.unavailable;
  }

  @override
  Future<void> start(void Function(String words) onWords) async {
    _words = '';
    await _speech.listen(
      onResult: (result) {
        _words = result.recognizedWords;
        onWords(_words);
      },
      listenOptions: SpeechListenOptions(
        localeId: kArabicSpeechLocaleId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Future<String> stop() async {
    await _speech.stop();
    return _words;
  }

  @override
  Future<void> cancel() => _speech.cancel();
}
```

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib/features/memorization_plus/data/listening test/features/memorization_plus/data/listening
flutter analyze lib/features/memorization_plus/data/listening test/features/memorization_plus/data/listening
git add lib/features/memorization_plus/data/listening test/features/memorization_plus/data/listening
git commit -m "feat(listening): add owner-scoped stats store and audio/speech adapters"
```

---

### Task 5: ListeningReviewCubit

**Files:**
- Create: `lib/features/memorization_plus/presentation/cubits/listening_review_state.dart`
- Create: `lib/features/memorization_plus/presentation/cubits/listening_review_cubit.dart`
- Test: `test/features/memorization_plus/presentation/cubits/listening_review_cubit_test.dart`

**Interfaces:**
- Consumes: Tasks 1–4 (`ListeningQuizSource`, `ListeningQuizMaterial`, `ListeningQuizEngine`, `ListeningAudio`, `ListeningRecitationCapture`, `ListeningCaptureReadiness`, `ListeningReviewStatsStore`, `ListeningReviewStats`, `ListeningRoundResult`), `V2RecitationEvaluator` (`lib/core/memorization/v2/recitation_evaluator.dart`: `evaluate({required String targetText, required String spokenText})` → `V2RecitationResult` with `passed`, `isNoAttempt`).
- Produces (used by Task 6 UI):
  - States: `ListeningReviewLoading`, `ListeningReviewError`, `ListeningReviewNotEnough`, `ListeningReviewIdle(stats)`, `ListeningReviewInRound(...)`, `ListeningReviewFinished(result)`; all `sealed class ListeningReviewState`.
  - `ListeningReviewInRound` fields: `mode`, `questions`, `index`, `answers`, `playsUsed`, `isPlaying`, `isRecording`, `recognizedText`, `emptyAttempts`, `selfGradeMode`, `selfGradeRevealed`, `current` (`ListeningAnswer?`, non-null once the current question is answered), getters `question`, `isAnswered`, `playsLeft`.
  - Cubit: `ListeningReviewCubit({required ListeningQuizSource source, required ListeningAudio audio, required ListeningRecitationCapture capture, required ListeningReviewStatsStore stats, ListeningQuizEngine engine = const ListeningQuizEngine(), V2RecitationEvaluator evaluator = const V2RecitationEvaluator(), Random? random})`
  - Methods: `load()`, `startRound(ListeningQuizMode)`, `replay()`, `answerSurah(int)`, `startRecording()`, `stopRecording()`, `useSelfGrade()`, `revealForSelfGrade()`, `selfGrade(ListeningOutcome)`, `next()`, `backToStart()`, getter `ListeningQuizMaterial? material`.

- [ ] **Step 1: Write the state file** (plain data; tested through the cubit)

`lib/features/memorization_plus/presentation/cubits/listening_review_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/listening/listening_quiz_engine.dart';
import '../../../../core/memorization/listening/listening_round_result.dart';
import '../../data/listening/listening_review_stats_store.dart';

sealed class ListeningReviewState extends Equatable {
  const ListeningReviewState();

  @override
  List<Object?> get props => [];
}

final class ListeningReviewLoading extends ListeningReviewState {
  const ListeningReviewLoading();
}

final class ListeningReviewError extends ListeningReviewState {
  const ListeningReviewError();
}

/// Fewer than [ListeningQuizEngine.minQuestions] playable questions.
final class ListeningReviewNotEnough extends ListeningReviewState {
  const ListeningReviewNotEnough();
}

final class ListeningReviewIdle extends ListeningReviewState {
  const ListeningReviewIdle(this.stats);

  final ListeningReviewStats stats;

  @override
  List<Object?> get props => [stats];
}

final class ListeningReviewInRound extends ListeningReviewState {
  const ListeningReviewInRound({
    required this.mode,
    required this.questions,
    required this.index,
    this.answers = const [],
    this.current,
    this.playsUsed = 0,
    this.isPlaying = false,
    this.isRecording = false,
    this.recognizedText = '',
    this.emptyAttempts = 0,
    this.selfGradeMode = false,
    this.selfGradeRevealed = false,
  });

  final ListeningQuizMode mode;
  final List<ListeningQuestion> questions;
  final int index;
  final List<ListeningAnswer> answers;

  /// Answer to the current question once given (drives the reveal view).
  final ListeningAnswer? current;
  final int playsUsed;
  final bool isPlaying;
  final bool isRecording;
  final String recognizedText;
  final int emptyAttempts;

  /// Speech unavailable or declined → reveal + self-grade for this question.
  final bool selfGradeMode;
  final bool selfGradeRevealed;

  ListeningQuestion get question => questions[index];
  bool get isAnswered => current != null;
  int get playsLeft => ListeningQuizEngine.maxPlays - playsUsed;

  ListeningReviewInRound copyWith({
    int? index,
    List<ListeningAnswer>? answers,
    ListeningAnswer? current,
    bool clearCurrent = false,
    int? playsUsed,
    bool? isPlaying,
    bool? isRecording,
    String? recognizedText,
    int? emptyAttempts,
    bool? selfGradeMode,
    bool? selfGradeRevealed,
  }) => ListeningReviewInRound(
    mode: mode,
    questions: questions,
    index: index ?? this.index,
    answers: answers ?? this.answers,
    current: clearCurrent ? null : (current ?? this.current),
    playsUsed: playsUsed ?? this.playsUsed,
    isPlaying: isPlaying ?? this.isPlaying,
    isRecording: isRecording ?? this.isRecording,
    recognizedText: recognizedText ?? this.recognizedText,
    emptyAttempts: emptyAttempts ?? this.emptyAttempts,
    selfGradeMode: selfGradeMode ?? this.selfGradeMode,
    selfGradeRevealed: selfGradeRevealed ?? this.selfGradeRevealed,
  );

  @override
  List<Object?> get props => [
    mode,
    questions,
    index,
    answers,
    current,
    playsUsed,
    isPlaying,
    isRecording,
    recognizedText,
    emptyAttempts,
    selfGradeMode,
    selfGradeRevealed,
  ];
}

final class ListeningReviewFinished extends ListeningReviewState {
  const ListeningReviewFinished(this.result);

  final ListeningRoundResult result;

  @override
  List<Object?> get props => [result];
}
```

- [ ] **Step 2: Write the failing cubit test**

`test/features/memorization_plus/presentation/cubits/listening_review_cubit_test.dart`:

```dart
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_round_result.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_audio.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_quiz_source.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_recitation_capture.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_review_stats_store.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/listening_review_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/listening_review_state.dart';

class _MockSource extends Mock implements ListeningQuizSource {}

class _MockAudio extends Mock implements ListeningAudio {}

class _MockCapture extends Mock implements ListeningRecitationCapture {}

ListeningQuizMaterial _material({int promptCount = 12}) {
  final corpus = ListeningCorpus.fromTexts({
    for (var s = 1; s <= 114; s++)
      s: [for (var a = 1; a <= 20; a++) 'surah $s ayah $a'],
  });
  return ListeningQuizMaterial(
    corpus: corpus,
    prompts: [for (var a = 1; a <= promptCount; a++) ListeningAyahRef(10, a)],
    surahs: const {},
  );
}

void main() {
  late _MockSource source;
  late _MockAudio audio;
  late _MockCapture capture;
  late ListeningReviewStatsStore stats;

  setUpAll(() {
    registerFallbackValue(const ListeningAyahRef(1, 1));
    registerFallbackValue((String _) {}); // for capture.start(any())
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = ListeningReviewStatsStore(
      await SharedPreferences.getInstance(),
      const FixedRecordOwnerProvider('owner-a'),
    );
    source = _MockSource();
    audio = _MockAudio();
    capture = _MockCapture();
    when(() => audio.isCached(any())).thenAnswer((_) async => true);
    when(() => audio.play(any())).thenAnswer((_) async => true);
    when(() => audio.stop()).thenAnswer((_) async {});
    when(() => audio.dispose()).thenAnswer((_) async {});
    when(() => capture.cancel()).thenAnswer((_) async {});
  });

  ListeningReviewCubit build() => ListeningReviewCubit(
    source: source,
    audio: audio,
    capture: capture,
    stats: stats,
    random: Random(5),
  );

  test('load → idle with stats when the pool is large enough', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    final cubit = build();
    await cubit.load();
    expect(cubit.state, const ListeningReviewIdle(ListeningReviewStats.empty));
  });

  test('load → not enough when fewer than 5 eligible prompts', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material(promptCount: 4)));
    final cubit = build();
    await cubit.load();
    expect(cubit.state, isA<ListeningReviewNotEnough>());
  });

  test('load → error when the source fails', () async {
    when(() => source.load()).thenAnswer((_) async => const Left(CacheFailure()));
    final cubit = build();
    await cubit.load();
    expect(cubit.state, isA<ListeningReviewError>());
  });

  test('which-surah round: answering records outcome once and plays audio', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.whichSurah);

    final round = cubit.state as ListeningReviewInRound;
    expect(round.questions, hasLength(10));
    verify(() => audio.play(round.question.prompt)).called(1);

    final q = round.question as WhichSurahQuestion;
    final wrong = q.optionSurahIds.firstWhere((s) => s != q.prompt.surahId);
    cubit.answerSurah(wrong);
    cubit.answerSurah(q.prompt.surahId); // ignored: already answered
    final answered = cubit.state as ListeningReviewInRound;
    expect(answered.current!.outcome, ListeningOutcome.wrong);
  });

  test('replay is capped at 3 plays per question', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.whichSurah);
    await cubit.replay();
    await cubit.replay();
    await cubit.replay(); // 4th play refused
    final round = cubit.state as ListeningReviewInRound;
    expect(round.playsUsed, 3);
    verify(() => audio.play(round.question.prompt)).called(3);
  });

  test('audio failure skips the question without scoring it', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    var calls = 0;
    when(() => audio.play(any())).thenAnswer((_) async => calls++ != 0);
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.whichSurah);
    final round = cubit.state as ListeningReviewInRound;
    expect(round.index, 1);
    expect(round.answers.single.outcome, ListeningOutcome.skipped);
  });

  test('finishing a round writes stats and emits the result', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.whichSurah);
    for (var i = 0; i < 10; i++) {
      final q = (cubit.state as ListeningReviewInRound).question as WhichSurahQuestion;
      cubit.answerSurah(q.prompt.surahId);
      await cubit.next();
    }
    final finished = cubit.state as ListeningReviewFinished;
    expect(finished.result.correct, 10);
    expect(stats.read().bestPercent, 100);
  });

  test('next-ayah: recognized recitation is scored with the evaluator', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    when(() => capture.prepare()).thenAnswer((_) async => ListeningCaptureReadiness.ready);
    when(() => capture.start(any())).thenAnswer((_) async {});
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.nextAyah);
    final q = (cubit.state as ListeningReviewInRound).question as NextAyahQuestion;
    when(() => capture.stop()).thenAnswer((_) async => q.nextAyahText);

    await cubit.startRecording();
    await cubit.stopRecording();

    final round = cubit.state as ListeningReviewInRound;
    expect(round.current!.outcome, ListeningOutcome.correct);
  });

  test('next-ayah: two empty recognitions switch to self-grade', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    when(() => capture.prepare()).thenAnswer((_) async => ListeningCaptureReadiness.ready);
    when(() => capture.start(any())).thenAnswer((_) async {});
    when(() => capture.stop()).thenAnswer((_) async => '');
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.nextAyah);

    await cubit.startRecording();
    await cubit.stopRecording();
    expect((cubit.state as ListeningReviewInRound).selfGradeMode, isFalse);
    await cubit.startRecording();
    await cubit.stopRecording();
    final round = cubit.state as ListeningReviewInRound;
    expect(round.selfGradeMode, isTrue);
    expect(round.isAnswered, isFalse);
  });

  test('next-ayah: denied microphone falls back to self-grade', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    when(() => capture.prepare())
        .thenAnswer((_) async => ListeningCaptureReadiness.permissionDenied);
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.nextAyah);
    await cubit.startRecording();
    expect((cubit.state as ListeningReviewInRound).selfGradeMode, isTrue);

    cubit.revealForSelfGrade();
    cubit.selfGrade(ListeningOutcome.hesitant);
    expect(
      (cubit.state as ListeningReviewInRound).current!.outcome,
      ListeningOutcome.hesitant,
    );
  });
}
```

(The spec's "no calls to `saveReviewRecord` or the outcome committer" is guaranteed structurally: the cubit's constructor takes no repository or committer, so it cannot write records. The reviewer checks this in Task 5's diff.)

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/features/memorization_plus/presentation/cubits/listening_review_cubit_test.dart`
Expected: FAIL — `listening_review_cubit.dart` not found.

- [ ] **Step 4: Implement the cubit**

`lib/features/memorization_plus/presentation/cubits/listening_review_cubit.dart`:

```dart
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/listening/listening_quiz_engine.dart';
import '../../../../core/memorization/listening/listening_round_result.dart';
import '../../../../core/memorization/v2/recitation_evaluator.dart';
import '../../data/listening/listening_audio.dart';
import '../../data/listening/listening_quiz_source.dart';
import '../../data/listening/listening_recitation_capture.dart';
import '../../data/listening/listening_review_stats_store.dart';
import 'listening_review_state.dart';

/// Drives Listening Review rounds. Practice only: it has no access to review
/// records, the outcome committer, XP or sync, so it cannot change SRS.
class ListeningReviewCubit extends Cubit<ListeningReviewState> {
  ListeningReviewCubit({
    required ListeningQuizSource source,
    required ListeningAudio audio,
    required ListeningRecitationCapture capture,
    required ListeningReviewStatsStore stats,
    ListeningQuizEngine engine = const ListeningQuizEngine(),
    V2RecitationEvaluator evaluator = const V2RecitationEvaluator(),
    Random? random,
  }) : _source = source,
       _audio = audio,
       _capture = capture,
       _stats = stats,
       _engine = engine,
       _evaluator = evaluator,
       _random = random ?? Random(),
       super(const ListeningReviewLoading());

  final ListeningQuizSource _source;
  final ListeningAudio _audio;
  final ListeningRecitationCapture _capture;
  final ListeningReviewStatsStore _stats;
  final ListeningQuizEngine _engine;
  final V2RecitationEvaluator _evaluator;
  final Random _random;

  ListeningQuizMaterial? _material;
  ListeningQuizMaterial? get material => _material;

  Future<void> load() async {
    emit(const ListeningReviewLoading());
    final result = await _source.load();
    result.fold((_) => emit(const ListeningReviewError()), (material) {
      _material = material;
      final eligible = _engine.eligiblePromptCount(
        material.corpus,
        material.prompts,
      );
      emit(
        eligible < ListeningQuizEngine.minQuestions
            ? const ListeningReviewNotEnough()
            : ListeningReviewIdle(_stats.read()),
      );
    });
  }

  Future<void> startRound(ListeningQuizMode mode) async {
    final material = _material;
    if (material == null) return;
    final candidates = _engine.buildRound(
      corpus: material.corpus,
      prompts: material.prompts,
      mode: mode,
      random: _random,
      size: ListeningQuizEngine.candidateSize,
    );
    final cached = <ListeningQuestion>[];
    final uncached = <ListeningQuestion>[];
    for (final q in candidates) {
      (await _audio.isCached(q.prompt) ? cached : uncached).add(q);
    }
    final questions = [
      ...cached,
      ...uncached,
    ].take(ListeningQuizEngine.roundSize).toList();
    if (questions.length < ListeningQuizEngine.minQuestions) {
      emit(const ListeningReviewNotEnough());
      return;
    }
    emit(ListeningReviewInRound(mode: mode, questions: questions, index: 0));
    await _playCurrent();
  }

  Future<void> replay() => _playCurrent();

  void answerSurah(int surahId) {
    final st = state;
    if (st is! ListeningReviewInRound || st.isAnswered) return;
    final question = st.question;
    if (question is! WhichSurahQuestion) return;
    _answer(
      st,
      surahId == question.prompt.surahId
          ? ListeningOutcome.correct
          : ListeningOutcome.wrong,
    );
  }

  Future<void> startRecording() async {
    final st = state;
    if (st is! ListeningReviewInRound ||
        st.isAnswered ||
        st.isRecording ||
        st.question is! NextAyahQuestion) {
      return;
    }
    if (st.isPlaying) await _audio.stop();
    final readiness = await _capture.prepare();
    if (readiness != ListeningCaptureReadiness.ready) {
      emit(st.copyWith(selfGradeMode: true, isPlaying: false));
      return;
    }
    emit(st.copyWith(isRecording: true, recognizedText: '', isPlaying: false));
    await _capture.start((words) {
      final current = state;
      if (current is ListeningReviewInRound && current.isRecording) {
        emit(current.copyWith(recognizedText: words));
      }
    });
  }

  Future<void> stopRecording() async {
    final st = state;
    if (st is! ListeningReviewInRound || !st.isRecording) return;
    final spoken = await _capture.stop();
    final question = st.question as NextAyahQuestion;
    final result = _evaluator.evaluate(
      targetText: question.nextAyahText,
      spokenText: spoken,
    );
    final stopped = st.copyWith(isRecording: false, recognizedText: spoken);
    if (result.isNoAttempt) {
      final attempts = stopped.emptyAttempts + 1;
      emit(stopped.copyWith(emptyAttempts: attempts, selfGradeMode: attempts >= 2));
      return;
    }
    _answer(
      stopped,
      result.passed ? ListeningOutcome.correct : ListeningOutcome.wrong,
    );
  }

  void useSelfGrade() {
    final st = state;
    if (st is ListeningReviewInRound && !st.isAnswered) {
      emit(st.copyWith(selfGradeMode: true));
    }
  }

  void revealForSelfGrade() {
    final st = state;
    if (st is ListeningReviewInRound && st.selfGradeMode && !st.isAnswered) {
      emit(st.copyWith(selfGradeRevealed: true));
    }
  }

  void selfGrade(ListeningOutcome outcome) {
    final st = state;
    if (st is! ListeningReviewInRound ||
        st.isAnswered ||
        !st.selfGradeRevealed ||
        outcome == ListeningOutcome.skipped) {
      return;
    }
    _answer(st, outcome);
  }

  Future<void> next() async {
    final st = state;
    if (st is! ListeningReviewInRound || !st.isAnswered) return;
    await _advance(st, st.answers);
  }

  Future<void> backToStart() async {
    await _audio.stop();
    if (_material == null) {
      await load();
      return;
    }
    emit(ListeningReviewIdle(_stats.read()));
  }

  void _answer(ListeningReviewInRound st, ListeningOutcome outcome) {
    final answer = ListeningAnswer(st.question, outcome);
    emit(st.copyWith(current: answer, answers: [...st.answers, answer]));
  }

  Future<void> _playCurrent() async {
    final st = state;
    if (st is! ListeningReviewInRound ||
        st.isPlaying ||
        st.isRecording ||
        st.playsLeft <= 0) {
      return;
    }
    emit(st.copyWith(isPlaying: true, playsUsed: st.playsUsed + 1));
    final played = await _audio.play(st.question.prompt);
    final after = state;
    if (after is! ListeningReviewInRound || after.index != st.index) return;
    if (played) {
      emit(after.copyWith(isPlaying: false));
      return;
    }
    // Audio unavailable (e.g. offline, not cached): skip without scoring.
    await _advance(after, [
      ...after.answers,
      ListeningAnswer(after.question, ListeningOutcome.skipped),
    ]);
  }

  Future<void> _advance(
    ListeningReviewInRound st,
    List<ListeningAnswer> answers,
  ) async {
    if (st.index + 1 >= st.questions.length) {
      final result = ListeningRoundResult(answers);
      await _stats.record(result);
      emit(ListeningReviewFinished(result));
      return;
    }
    emit(
      ListeningReviewInRound(
        mode: st.mode,
        questions: st.questions,
        index: st.index + 1,
        answers: answers,
      ),
    );
    await _playCurrent();
  }

  @override
  Future<void> close() async {
    await _capture.cancel();
    await _audio.dispose();
    return super.close();
  }
}
```

Before running, confirm `V2RecitationResult` exposes `isNoAttempt` and `passed` (both are declared in `recitation_evaluator.dart`, lines ~188–218).

- [ ] **Step 5: Run the cubit test**

Run: `flutter test test/features/memorization_plus/presentation/cubits/listening_review_cubit_test.dart`
Expected: PASS. In the "audio failure" test, the first `play` returns false (skip → index 1), the second returns true.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib/features/memorization_plus/presentation/cubits/listening_review_state.dart lib/features/memorization_plus/presentation/cubits/listening_review_cubit.dart test/features/memorization_plus/presentation/cubits/listening_review_cubit_test.dart
flutter analyze lib/features/memorization_plus/presentation/cubits test/features/memorization_plus/presentation/cubits/listening_review_cubit_test.dart
git add lib/features/memorization_plus/presentation/cubits/listening_review_state.dart lib/features/memorization_plus/presentation/cubits/listening_review_cubit.dart test/features/memorization_plus/presentation/cubits/listening_review_cubit_test.dart
git commit -m "feat(listening): add listening review cubit"
```

---

### Task 6: Listening review page, strings, and weak-link route

**Files:**
- Modify: `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb` (append keys next to `memorizationHubPracticeBySurahDescription`)
- Modify: `lib/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart` (add static `reviewAyahLocation`)
- Create: `lib/features/memorization_plus/presentation/pages/listening_review_page.dart`
- Create: `lib/features/memorization_plus/presentation/widgets/listening_review_views.dart`
- Test: `test/features/memorization_plus/presentation/pages/listening_review_page_test.dart`

**Interfaces:**
- Consumes: Task 5 cubit + states; `MemorizationAyahDisplay` (`lib/core/widgets/memorization_ayah_display.dart`), `V2PhaseCard` (`.../pages/v2/v2_session_widgets.dart`), `AppSpacing`, `AppColors`, `context.l10n`, `context.isDark`; `LearningLaunchContext`, `AyahReference`, `LearningIntent.review`, `LearningOrigin.review`.
- Produces:
  - `MemorizationNavigationResolver.reviewAyahLocation(int surahId, int ayahNumber)` → `String`
  - `ListeningReviewPage` (provides the cubit from `getIt` and calls `load()`), `ListeningReviewView` (takes the cubit from context; used directly in tests)

- [ ] **Step 1: Add the l10n keys**

In `lib/core/l10n/app_ar.arb`, after `"memorizationHubPracticeBySurahDescription"`:

```json
  "listeningReviewTitle": "مراجعة بالسماع",
  "listeningReviewHubDescription": "اسمع آية من محفوظك: حدّد سورتها أو أكمل ما بعدها.",
  "listeningReviewStartPrompt": "اختر نوع الجولة",
  "listeningReviewModeWhichSurah": "من أي سورة؟",
  "listeningReviewModeNextAyah": "أكمل التالية",
  "listeningReviewModeMixed": "مختلط",
  "listeningReviewLastScore": "آخر جولة: {correct} من {total}",
  "@listeningReviewLastScore": {"placeholders": {"correct": {"type": "int"}, "total": {"type": "int"}}},
  "listeningReviewNotEnoughTitle": "احفظ بضع آيات أولًا",
  "listeningReviewNotEnoughBody": "تحتاج المراجعة بالسماع إلى 5 آيات محفوظة على الأقل يمكن تشغيلها.",
  "listeningReviewErrorBody": "تعذّر تحضير الجولة. حاول مرة أخرى.",
  "listeningReviewRetry": "إعادة المحاولة",
  "listeningReviewQuestionProgress": "السؤال {current} من {total}",
  "@listeningReviewQuestionProgress": {"placeholders": {"current": {"type": "int"}, "total": {"type": "int"}}},
  "listeningReviewReplay": "أعد الاستماع ({remaining})",
  "@listeningReviewReplay": {"placeholders": {"remaining": {"type": "int"}}},
  "listeningReviewWhichSurahPrompt": "من أي سورة هذه الآية؟",
  "listeningReviewNextAyahPrompt": "سورة {surah}: اتلُ الآية التالية",
  "@listeningReviewNextAyahPrompt": {"placeholders": {"surah": {"type": "String"}}},
  "listeningReviewRecord": "ابدأ التسميع",
  "listeningReviewStopRecord": "إنهاء التسميع",
  "listeningReviewCantRecord": "لا أستطيع التسجيل",
  "listeningReviewReveal": "أظهر الآية",
  "listeningReviewGradeMastered": "أتقنت",
  "listeningReviewGradeHesitant": "ترددت",
  "listeningReviewGradeForgot": "نسيت",
  "listeningReviewCorrect": "إجابة صحيحة",
  "listeningReviewWrong": "ليست هذه",
  "listeningReviewNext": "التالي",
  "listeningReviewResultTitle": "انتهت الجولة",
  "listeningReviewResultScore": "{correct} من {total}",
  "@listeningReviewResultScore": {"placeholders": {"correct": {"type": "int"}, "total": {"type": "int"}}},
  "listeningReviewWeakLinksTitle": "روابط تحتاج مراجعة",
  "listeningReviewNoWeakLinks": "لا توجد روابط ضعيفة في هذه الجولة",
  "listeningReviewAyahRef": "سورة {surah} · الآية {ayah}",
  "@listeningReviewAyahRef": {"placeholders": {"surah": {"type": "String"}, "ayah": {"type": "int"}}},
  "listeningReviewNewRound": "جولة جديدة",
```

In `lib/core/l10n/app_en.arb`, after `"memorizationHubPracticeBySurahDescription"`:

```json
  "listeningReviewTitle": "Listening Review",
  "listeningReviewHubDescription": "Hear an ayah you memorized: name its surah or recite what comes next.",
  "listeningReviewStartPrompt": "Choose a round type",
  "listeningReviewModeWhichSurah": "Which surah?",
  "listeningReviewModeNextAyah": "Continue the next ayah",
  "listeningReviewModeMixed": "Mixed",
  "listeningReviewLastScore": "Last round: {correct} of {total}",
  "listeningReviewNotEnoughTitle": "Memorize a few ayahs first",
  "listeningReviewNotEnoughBody": "Listening review needs at least 5 memorized ayahs that can be played.",
  "listeningReviewErrorBody": "Couldn't prepare the round. Please try again.",
  "listeningReviewRetry": "Try again",
  "listeningReviewQuestionProgress": "Question {current} of {total}",
  "listeningReviewReplay": "Replay ({remaining})",
  "listeningReviewWhichSurahPrompt": "Which surah is this ayah from?",
  "listeningReviewNextAyahPrompt": "Surah {surah}: recite the next ayah",
  "listeningReviewRecord": "Start reciting",
  "listeningReviewStopRecord": "Stop",
  "listeningReviewCantRecord": "I can't record",
  "listeningReviewReveal": "Reveal the ayah",
  "listeningReviewGradeMastered": "Got it",
  "listeningReviewGradeHesitant": "Hesitated",
  "listeningReviewGradeForgot": "Forgot",
  "listeningReviewCorrect": "Correct",
  "listeningReviewWrong": "Not quite",
  "listeningReviewNext": "Next",
  "listeningReviewResultTitle": "Round complete",
  "listeningReviewResultScore": "{correct} of {total}",
  "listeningReviewWeakLinksTitle": "Links to review",
  "listeningReviewNoWeakLinks": "No weak links this round",
  "listeningReviewAyahRef": "Surah {surah} · Ayah {ayah}",
  "listeningReviewNewRound": "New round",
```

Run: `flutter gen-l10n`
Expected: completes; `lib/core/l10n/app_localizations.dart` now has `listeningReviewTitle`.

- [ ] **Step 2: Add the weak-link route builder**

In `lib/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart`, add next to `dailyPlanAyahLocation`:

```dart
  /// Review session for one ayah (Listening Review weak links). Recall work
  /// on known material, so always a review — never re-teaching.
  static String reviewAyahLocation(int surahId, int ayahNumber) {
    final launchContext = LearningLaunchContext(
      ayah: AyahReference(surahId: surahId, ayahNumber: ayahNumber),
      intent: LearningIntent.review,
      origin: LearningOrigin.review,
    );
    return Uri(
      path: AppRoutes.memorizationV2Session,
      queryParameters: launchContext.toRouteQuery(),
    ).toString();
  }
```

- [ ] **Step 3: Write the failing page test**

`test/features/memorization_plus/presentation/pages/listening_review_page_test.dart` — the view is pumped with a mocked cubit (mocktail + `MockCubit`-free approach: a real cubit with fakes is heavy, so stub `state`/`stream`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_round_result.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_quiz_source.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_review_stats_store.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/listening_review_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/listening_review_state.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/listening_review_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

class _MockCubit extends Mock implements ListeningReviewCubit {}

Surah _surah(int id) => Surah(
  id: id, nameAr: 'سورة $id', nameEn: 'S$id', ayahCount: 3, juz: 1, type: 'meccan', page: 1,
);

final _material = ListeningQuizMaterial(
  corpus: ListeningCorpus.fromTexts({2: ['a', 'b', 'c']}),
  prompts: const [],
  surahs: {for (var s = 1; s <= 5; s++) s: _surah(s)},
);

Future<_MockCubit> _pump(WidgetTester tester, ListeningReviewState state) async {
  final cubit = _MockCubit();
  when(() => cubit.state).thenReturn(state);
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.material).thenReturn(_material);
  when(() => cubit.close()).thenAnswer((_) async {});
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<ListeningReviewCubit>.value(
        value: cubit,
        child: const ListeningReviewView(),
      ),
    ),
  );
  return cubit;
}

void main() {
  testWidgets('not-enough state explains the minimum', (tester) async {
    await _pump(tester, const ListeningReviewNotEnough());
    expect(find.text('Memorize a few ayahs first'), findsOneWidget);
  });

  testWidgets('idle shows the three modes and starts a round', (tester) async {
    final cubit = await _pump(tester, const ListeningReviewIdle(ListeningReviewStats.empty));
    when(() => cubit.startRound(ListeningQuizMode.whichSurah)).thenAnswer((_) async {});
    expect(find.text('Which surah?'), findsOneWidget);
    expect(find.text('Continue the next ayah'), findsOneWidget);
    expect(find.text('Mixed'), findsOneWidget);
    await tester.tap(find.text('Which surah?'));
    verify(() => cubit.startRound(ListeningQuizMode.whichSurah)).called(1);
  });

  testWidgets('tapping a surah option answers the question', (tester) async {
    const q = WhichSurahQuestion(ListeningAyahRef(2, 2), optionSurahIds: [1, 2, 3, 4]);
    final cubit = await _pump(
      tester,
      const ListeningReviewInRound(mode: ListeningQuizMode.whichSurah, questions: [q], index: 0),
    );
    await tester.tap(find.text('S3'));
    verify(() => cubit.answerSurah(3)).called(1);
  });

  testWidgets('answered question reveals canonical text and Next', (tester) async {
    const q = WhichSurahQuestion(ListeningAyahRef(2, 2), optionSurahIds: [1, 2, 3, 4]);
    await _pump(
      tester,
      const ListeningReviewInRound(
        mode: ListeningQuizMode.whichSurah,
        questions: [q],
        index: 0,
        current: ListeningAnswer(q, ListeningOutcome.wrong),
      ),
    );
    expect(find.text('Not quite'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('result lists weak links', (tester) async {
    const q = WhichSurahQuestion(ListeningAyahRef(2, 2), optionSurahIds: [1, 2, 3, 4]);
    await _pump(
      tester,
      const ListeningReviewFinished(
        ListeningRoundResult([ListeningAnswer(q, ListeningOutcome.wrong)]),
      ),
    );
    expect(find.text('Round complete'), findsOneWidget);
    expect(find.text('Links to review'), findsOneWidget);
    expect(find.text('Surah S2 · Ayah 2'), findsOneWidget);
  });
}
```

Check the l10n import path and `supportedLocales` against an existing widget test (e.g. the top of `test/features/memorization_plus/presentation/pages/memorization_hub_page_test.dart`); if it uses a shared pump helper, use that helper instead of the inline `MaterialApp`. `MemorizationAyahDisplay` may render the text plus a reference — if `find.text('b')` does not match, use `find.textContaining('b')`.

- [ ] **Step 4: Run it to verify it fails**

Run: `flutter test test/features/memorization_plus/presentation/pages/listening_review_page_test.dart`
Expected: FAIL — `listening_review_page.dart` not found.

- [ ] **Step 5: Implement the page**

`lib/features/memorization_plus/presentation/pages/listening_review_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../cubits/listening_review_cubit.dart';
import '../cubits/listening_review_state.dart';
import '../widgets/listening_review_views.dart';

/// Adult Listening Review ("مراجعة بالسماع"). Practice only — never changes SRS.
class ListeningReviewPage extends StatelessWidget {
  const ListeningReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ListeningReviewCubit>()..load(),
      child: const ListeningReviewView(),
    );
  }
}

class ListeningReviewView extends StatelessWidget {
  const ListeningReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.listeningReviewTitle)),
      body: SafeArea(
        child: BlocBuilder<ListeningReviewCubit, ListeningReviewState>(
          builder: (context, state) => switch (state) {
            ListeningReviewLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ListeningReviewError() => const ListeningErrorView(),
            ListeningReviewNotEnough() => const ListeningNotEnoughView(),
            ListeningReviewIdle(:final stats) => ListeningStartView(stats: stats),
            final ListeningReviewInRound round => ListeningQuestionView(
              round: round,
            ),
            ListeningReviewFinished(:final result) => ListeningResultView(
              result: result,
            ),
          },
        ),
      ),
    );
  }
}
```

Check `getIt` export path with `grep -n "final getIt" lib/core/di/injection.dart`.

- [ ] **Step 6: Implement the views**

`lib/features/memorization_plus/presentation/widgets/listening_review_views.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/listening/listening_round_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/memorization_ayah_display.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../data/listening/listening_review_stats_store.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../cubits/listening_review_cubit.dart';
import '../cubits/listening_review_state.dart';
import '../pages/v2/v2_session_widgets.dart';

String _surahName(BuildContext context, int surahId) {
  final Surah? surah = context
      .read<ListeningReviewCubit>()
      .material
      ?.surahs[surahId];
  if (surah == null) return '$surahId';
  return context.l10n.localeName == 'ar' ? surah.nameAr : surah.nameEn;
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class ListeningErrorView extends StatelessWidget {
  const ListeningErrorView({super.key});

  @override
  Widget build(BuildContext context) => _Centered(
    children: [
      Text(context.l10n.listeningReviewErrorBody, textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        onPressed: () => context.read<ListeningReviewCubit>().load(),
        child: Text(context.l10n.listeningReviewRetry),
      ),
    ],
  );
}

class ListeningNotEnoughView extends StatelessWidget {
  const ListeningNotEnoughView({super.key});

  @override
  Widget build(BuildContext context) => _Centered(
    children: [
      const Icon(Icons.hearing_rounded, size: 48),
      const SizedBox(height: AppSpacing.md),
      Text(
        context.l10n.listeningReviewNotEnoughTitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(context.l10n.listeningReviewNotEnoughBody, textAlign: TextAlign.center),
    ],
  );
}

class ListeningStartView extends StatelessWidget {
  const ListeningStartView({super.key, required this.stats});

  final ListeningReviewStats stats;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    Widget mode(IconData icon, String label, ListeningQuizMode value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        onPressed: () => cubit.startRound(value),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
    return _Centered(
      children: [
        const Icon(Icons.hearing_rounded, size: 48),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.listeningReviewStartPrompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (stats.hasPlayed) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.listeningReviewLastScore(stats.lastCorrect!, stats.lastScored!),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        mode(Icons.menu_book_rounded, l10n.listeningReviewModeWhichSurah, ListeningQuizMode.whichSurah),
        mode(Icons.link_rounded, l10n.listeningReviewModeNextAyah, ListeningQuizMode.nextAyah),
        mode(Icons.shuffle_rounded, l10n.listeningReviewModeMixed, ListeningQuizMode.mixed),
      ],
    );
  }
}

class ListeningQuestionView extends StatelessWidget {
  const ListeningQuestionView({super.key, required this.round});

  final ListeningReviewInRound round;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    final question = round.question;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.listeningReviewQuestionProgress(round.index + 1, round.questions.length),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          switch (question) {
            WhichSurahQuestion() => l10n.listeningReviewWhichSurahPrompt,
            NextAyahQuestion(:final prompt) =>
              l10n.listeningReviewNextAyahPrompt(_surahName(context, prompt.surahId)),
          },
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: round.isPlaying || round.playsLeft <= 0 || round.isAnswered
              ? null
              : cubit.replay,
          icon: Icon(round.isPlaying ? Icons.graphic_eq_rounded : Icons.replay_rounded),
          label: Text(l10n.listeningReviewReplay(round.playsLeft)),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (round.isAnswered)
          _Reveal(round: round)
        else
          switch (question) {
            final WhichSurahQuestion q => _SurahOptions(question: q),
            NextAyahQuestion() => _NextAyahControls(round: round),
          },
      ],
    );
  }
}

class _SurahOptions extends StatelessWidget {
  const _SurahOptions({required this.question});

  final WhichSurahQuestion question;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final surahId in question.optionSurahIds)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: () => cubit.answerSurah(surahId),
              child: Text(_surahName(context, surahId)),
            ),
          ),
      ],
    );
  }
}

class _NextAyahControls extends StatelessWidget {
  const _NextAyahControls({required this.round});

  final ListeningReviewInRound round;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    if (round.selfGradeMode) {
      if (!round.selfGradeRevealed) {
        return FilledButton(
          onPressed: cubit.revealForSelfGrade,
          child: Text(l10n.listeningReviewReveal),
        );
      }
      final question = round.question as NextAyahQuestion;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AyahCard(ref: question.answer, text: question.nextAyahText),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final (label, outcome) in [
                (l10n.listeningReviewGradeMastered, ListeningOutcome.correct),
                (l10n.listeningReviewGradeHesitant, ListeningOutcome.hesitant),
                (l10n.listeningReviewGradeForgot, ListeningOutcome.wrong),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: OutlinedButton(
                      onPressed: () => cubit.selfGrade(outcome),
                      child: Text(label),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (round.recognizedText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(round.recognizedText, textAlign: TextAlign.center),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: round.isRecording ? cubit.stopRecording : cubit.startRecording,
          icon: Icon(round.isRecording ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(
            round.isRecording ? l10n.listeningReviewStopRecord : l10n.listeningReviewRecord,
          ),
        ),
        TextButton(
          onPressed: round.isRecording ? null : cubit.useSelfGrade,
          child: Text(l10n.listeningReviewCantRecord),
        ),
      ],
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({required this.ref, required this.text});

  final ListeningAyahRef ref;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return V2PhaseCard(
      child: MemorizationAyahDisplay(
        text: text,
        surahId: ref.surahId,
        ayahNumber: ref.ayahNumber,
        textColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        decorationColor: (isDark ? AppColors.primaryLight : AppColors.primary)
            .withValues(alpha: 0.5),
        referenceColor: isDark ? AppColors.primaryLight : AppColors.primary,
        isCompleted: false,
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.round});

  final ListeningReviewInRound round;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    final answer = round.current!;
    final ok = answer.outcome == ListeningOutcome.correct;
    final ref = answer.reviewTarget;
    final text = cubit.material?.corpus.textOf(ref) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ok ? l10n.listeningReviewCorrect : l10n.listeningReviewWrong,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ok ? AppColors.primary : Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AyahCard(ref: ref, text: text),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.listeningReviewAyahRef(_surahName(context, ref.surahId), ref.ayahNumber),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: cubit.next, child: Text(l10n.listeningReviewNext)),
      ],
    );
  }
}

class ListeningResultView extends StatelessWidget {
  const ListeningResultView({super.key, required this.result});

  final ListeningRoundResult result;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ListeningReviewCubit>();
    final l10n = context.l10n;
    final weak = result.weakLinks;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          l10n.listeningReviewResultTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.listeningReviewResultScore(result.correct, result.scored),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.listeningReviewWeakLinksTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (weak.isEmpty)
          Text(l10n.listeningReviewNoWeakLinks)
        else
          for (final ref in weak)
            ListTile(
              leading: const Icon(Icons.link_off_rounded),
              title: Text(
                l10n.listeningReviewAyahRef(_surahName(context, ref.surahId), ref.ayahNumber),
              ),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => context.push(
                MemorizationNavigationResolver.reviewAyahLocation(ref.surahId, ref.ayahNumber),
              ),
            ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: cubit.backToStart, child: Text(l10n.listeningReviewNewRound)),
      ],
    );
  }
}
```

Check before running: `AppSpacing.xs` exists (`grep -n "static const double xs" lib/core/constants/app_spacing.dart`; use `AppSpacing.sm` if not), and `context.l10n.localeName` is available (generated `AppLocalizations` has `localeName`). In the test, `_surahName` returns `nameEn` ("S3") because the locale is `en`.

- [ ] **Step 7: Run the page test**

Run: `flutter test test/features/memorization_plus/presentation/pages/listening_review_page_test.dart`
Expected: PASS.

- [ ] **Step 8: Format, analyze, commit**

```bash
dart format lib/features/memorization_plus/presentation/pages/listening_review_page.dart lib/features/memorization_plus/presentation/widgets/listening_review_views.dart lib/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart test/features/memorization_plus/presentation/pages/listening_review_page_test.dart
flutter analyze lib/features/memorization_plus test/features/memorization_plus/presentation/pages/listening_review_page_test.dart
git add lib/core/l10n/app_ar.arb lib/core/l10n/app_en.arb lib/core/l10n/app_localizations*.dart lib/features/memorization_plus/presentation/pages/listening_review_page.dart lib/features/memorization_plus/presentation/widgets/listening_review_views.dart lib/features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart test/features/memorization_plus/presentation/pages/listening_review_page_test.dart
git commit -m "feat(listening): add listening review page and weak-link review route"
```

(If `app_localizations*.dart` are git-ignored in this repo, `git add` will skip them — that is fine.)

---

### Task 7: Wire DI, route, and hub entry

**Files:**
- Modify: `lib/core/di/injection.dart` (near `PracticeSurahCubit` registration, ~line 766)
- Modify: `lib/core/router/app_router.dart` (`AppRoutes`, `_publicRoutes` list ~line 138, root routes near `memorizationPlusCustomPlan` ~line 850)
- Modify: `lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart` (Practice section, after the "Practice by Surah" card ~line 312)
- Modify: `test/features/memorization_plus/presentation/pages/memorization_hub_page_test.dart` (adult and kids hub tests)

**Interfaces:**
- Consumes: everything from Tasks 3–6.
- Produces: `AppRoutes.listeningReview = '/memorization/listening-review'`; `getIt<ListeningReviewCubit>()` factory.

- [ ] **Step 1: Extend the hub tests first (failing)**

In `memorization_hub_page_test.dart`, adult test (the one asserting `find.text('Practice by Surah')` at ~line 60), add:

```dart
      expect(find.text('Listening Review'), findsOneWidget);
```

In the kids test (asserting `find.text('Practice by Surah'), findsNothing` at ~line 93), add:

```dart
    expect(find.text('Listening Review'), findsNothing);
```

Run: `flutter test test/features/memorization_plus/presentation/pages/memorization_hub_page_test.dart`
Expected: FAIL — adult hub has no "Listening Review".

- [ ] **Step 2: Register DI**

In `lib/core/di/injection.dart`, after the `PracticeSurahCubit` registration:

```dart
  getIt.registerLazySingleton<ListeningQuizSource>(
    () => ListeningQuizSource(
      getIt<MemorizationPlusRepository>(),
      getIt<QuranRepository>(),
    ),
  );
  getIt.registerLazySingleton<ListeningReviewStatsStore>(
    () => ListeningReviewStatsStore(
      getIt<SharedPreferences>(),
      getIt<RecordOwnerProvider>(),
    ),
  );
  getIt.registerFactory<ListeningReviewCubit>(
    () => ListeningReviewCubit(
      source: getIt<ListeningQuizSource>(),
      audio: JustAudioListeningAudio(getIt<AudioCacheService>()),
      capture: SpeechToTextListeningCapture(),
      stats: getIt<ListeningReviewStatsStore>(),
    ),
  );
```

Add the imports at the top of `injection.dart` (keep its existing relative-import style):

```dart
import '../../features/memorization_plus/data/listening/listening_audio.dart';
import '../../features/memorization_plus/data/listening/listening_quiz_source.dart';
import '../../features/memorization_plus/data/listening/listening_recitation_capture.dart';
import '../../features/memorization_plus/data/listening/listening_review_stats_store.dart';
import '../../features/memorization_plus/presentation/cubits/listening_review_cubit.dart';
```

- [ ] **Step 3: Add the route**

In `AppRoutes` (after `hifzPracticeSurah`):

```dart
  static const String listeningReview = '/memorization/listening-review';
```

In `_publicRoutes`, after `AppRoutes.hifzPracticeSurah,`:

```dart
  AppRoutes.listeningReview,
```

In the root routes, next to the `memorizationPlusCustomPlan` `GoRoute` (same `parentNavigatorKey` pattern, full-screen without bottom nav):

```dart
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.listeningReview,
        redirect: (context, state) =>
            MemorizationRouteGuard.adultOnlyRedirect(),
        builder: (context, state) => const ListeningReviewPage(),
      ),
```

and import `ListeningReviewPage` alongside the other memorization page imports in `app_router.dart`.

- [ ] **Step 4: Add the hub card**

In `memorization_hub_page.dart`, in the adult Practice section right after the "Practice by Surah" `_HubActionCard`:

```dart
        const SizedBox(height: AppSpacing.sm),
        _HubActionCard(
          icon: Icons.hearing_rounded,
          title: context.l10n.listeningReviewTitle,
          description: context.l10n.listeningReviewHubDescription,
          route: AppRoutes.listeningReview,
          isDark: isDark,
        ),
```

(The adult section is only built when `profile?.isAdult == true`, so child profiles never see it.)

- [ ] **Step 5: Run the hub test and the whole listening suite**

Run: `flutter test test/features/memorization_plus/presentation/pages/memorization_hub_page_test.dart`
Expected: PASS.

Run: `flutter test test/core/memorization/listening test/assets/listening_quiz_corpus_contract_test.dart test/features/memorization_plus/data/listening test/features/memorization_plus/presentation/cubits/listening_review_cubit_test.dart test/features/memorization_plus/presentation/pages/listening_review_page_test.dart`
Expected: PASS.

- [ ] **Step 6: Full verification**

Run: `flutter analyze`
Expected: No issues.

Run: `flutter test`
Expected: all tests pass (compare against the baseline failure list if the tree already had failures before this work; report any new failure).

- [ ] **Step 7: Format, commit**

```bash
dart format lib/core/di/injection.dart lib/core/router/app_router.dart lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart test/features/memorization_plus/presentation/pages/memorization_hub_page_test.dart
git add lib/core/di/injection.dart lib/core/router/app_router.dart lib/features/memorization_plus/presentation/pages/memorization_hub_page.dart test/features/memorization_plus/presentation/pages/memorization_hub_page_test.dart
git commit -m "feat(listening): wire listening review into DI, router and memorization hub"
```

- [ ] **Step 8: Manual check on a device (report result, don't claim without it)**

`flutter run`, adult profile with ≥5 reviewed ayahs → Memorization hub → "مراجعة بالسماع": play a "which surah" round, a "next ayah" round with the mic, deny the mic once to see the self-grade path, turn off network to see an uncached question skipped, then open a weak link and confirm a V2 review session starts on that ayah.
