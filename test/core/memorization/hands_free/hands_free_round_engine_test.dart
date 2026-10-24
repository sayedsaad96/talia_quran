import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/hands_free/hands_free_round_engine.dart';
import 'package:talia_quran/core/memorization/hands_free/hands_free_round_state.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';

final _now = DateTime.utc(2026, 10, 23, 12);

ListeningCorpus _corpus({int ayahCount = 12}) => ListeningCorpus.fromTexts({
  1: List.generate(ayahCount, (index) => 'one $index'),
  2: List.generate(ayahCount, (index) => 'two $index'),
  3: List.generate(ayahCount, (index) => 'three $index'),
});

AyahReviewRecord _record({
  required int surahId,
  required int ayahNumber,
  DateTime? dueAt,
  int totalReviews = 1,
  ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.v2Session,
}) {
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: 4,
    intervalDays: 1,
    lastReviewedAt: _now.subtract(const Duration(days: 1)),
    nextReviewDate: dueAt ?? _now.subtract(const Duration(days: 1)),
    totalReviews: totalReviews,
    lastRating: PerformanceRating.average,
    createdByMode: mode,
  );
}

void main() {
  HandsFreeRoundEngine engine({ListeningCorpus? corpus}) =>
      HandsFreeRoundEngine(corpus: corpus ?? _corpus());

  group('start', () {
    test('selects the oldest eligible surah without crossing its boundary', () {
      final state = engine().start(
        due: [
          _record(
            surahId: 2,
            ayahNumber: 1,
            dueAt: _now.subtract(const Duration(days: 4)),
          ),
          _record(
            surahId: 1,
            ayahNumber: 2,
            dueAt: _now.subtract(const Duration(days: 2)),
          ),
          _record(
            surahId: 1,
            ayahNumber: 1,
            dueAt: _now.subtract(const Duration(days: 3)),
          ),
        ],
        now: _now,
      );

      expect(state.phase, HandsFreePhase.prompt);
      expect(state.items, const [ListeningAyahRef(2, 1)]);
    });

    test('limits a selected surah to ten prompts by default', () {
      final state = engine().start(
        due: [
          for (var ayah = 12; ayah >= 1; ayah--)
            _record(surahId: 1, ayahNumber: ayah),
        ],
        now: _now,
      );

      expect(state.items, hasLength(10));
      expect(state.items, const [
        ListeningAyahRef(1, 1),
        ListeningAyahRef(1, 2),
        ListeningAyahRef(1, 3),
        ListeningAyahRef(1, 4),
        ListeningAyahRef(1, 5),
        ListeningAyahRef(1, 6),
        ListeningAyahRef(1, 7),
        ListeningAyahRef(1, 8),
        ListeningAyahRef(1, 9),
        ListeningAyahRef(1, 10),
      ]);
    });

    test('uses surah and ayah identifiers as deterministic due-date ties', () {
      final state = engine().start(
        due: [
          _record(surahId: 2, ayahNumber: 2, dueAt: _now),
          _record(surahId: 1, ayahNumber: 2, dueAt: _now),
          _record(surahId: 1, ayahNumber: 1, dueAt: _now),
        ],
        now: _now,
      );

      expect(state.items, const [
        ListeningAyahRef(1, 1),
        ListeningAyahRef(1, 2),
      ]);
    });

    test('accepts a record due at the scheduled instant', () {
      final state = engine().start(
        due: [_record(surahId: 1, ayahNumber: 1, dueAt: _now)],
        now: _now,
      );

      expect(state.phase, HandsFreePhase.prompt);
      expect(state.currentAyah, const ListeningAyahRef(1, 1));
    });

    test('finishes immediately when no eligible due record exists', () {
      final state = engine().start(
        due: [
          _record(
            surahId: 1,
            ayahNumber: 1,
            dueAt: _now.add(const Duration(seconds: 1)),
          ),
        ],
        now: _now,
      );

      expect(state.phase, HandsFreePhase.finished);
      expect(engine().summarize(state), const HandsFreeRoundSummary.empty());
    });

    test('excludes child and unreviewed records from the listening pool', () {
      final state = engine().start(
        due: [
          _record(
            surahId: 1,
            ayahNumber: 1,
            mode: ReviewRecordCreatedByMode.kidsMode,
          ),
          _record(surahId: 1, ayahNumber: 2, totalReviews: 0),
        ],
        now: _now,
      );

      expect(state.phase, HandsFreePhase.finished);
    });

    test('deduplicates eligible refs without mutating the input', () {
      final records = [
        _record(surahId: 1, ayahNumber: 1),
        _record(surahId: 1, ayahNumber: 1),
      ];
      final original = List<AyahReviewRecord>.from(records);

      final state = engine().start(due: records, now: _now);

      expect(state.items, const [ListeningAyahRef(1, 1)]);
      expect(records, original);
      expect(
        () => state.items.add(const ListeningAyahRef(1, 2)),
        throwsUnsupportedError,
      );
    });

    test('fails closed when no eligible ref exists in the corpus', () {
      final state = engine().start(
        due: [_record(surahId: 1, ayahNumber: 13)],
        now: _now,
      );

      expect(state.phase, HandsFreePhase.finished);
      expect(state.items, isEmpty);
    });
  });

  group('round transitions', () {
    test('grades the current prompt ayah before advancing', () {
      final roundEngine = engine();
      final started = roundEngine.start(
        due: [
          _record(surahId: 1, ayahNumber: 1),
          _record(surahId: 1, ayahNumber: 2),
        ],
        now: _now,
      );
      final userTurn = roundEngine.onPromptFinished(started);
      final feedback = roundEngine.grade(userTurn, HandsFreeGrade.review);

      expect(feedback.phase, HandsFreePhase.feedback);
      expect(feedback.currentAyah, const ListeningAyahRef(1, 1));
      final summary = roundEngine.summarize(feedback);
      expect(summary.reviewAyahs, const [ListeningAyahRef(1, 1)]);
      expect(
        () => summary.reviewAyahs.add(const ListeningAyahRef(1, 2)),
        throwsUnsupportedError,
      );
      expect(
        roundEngine.next(feedback).currentAyah,
        const ListeningAyahRef(1, 2),
      );
    });

    test('keeps invalid phase transitions as the same state', () {
      final started = engine().start(
        due: [_record(surahId: 1, ayahNumber: 1)],
        now: _now,
      );

      expect(engine().grade(started, HandsFreeGrade.correct), same(started));
      expect(engine().next(started), same(started));
    });

    test(
      'interrupt excludes the current ungraded ayah and preserves history',
      () {
        final roundEngine = engine();
        final started = roundEngine.start(
          due: [
            _record(surahId: 1, ayahNumber: 1),
            _record(surahId: 1, ayahNumber: 2),
          ],
          now: _now,
        );
        final firstFeedback = roundEngine.grade(
          roundEngine.onPromptFinished(started),
          HandsFreeGrade.correct,
        );
        final secondPrompt = roundEngine.next(firstFeedback);
        final paused = roundEngine.interrupt(
          roundEngine.onPromptFinished(secondPrompt),
        );

        expect(paused.phase, HandsFreePhase.paused);
        expect(roundEngine.summarize(paused).correctCount, 1);
        expect(roundEngine.summarize(paused).reviewAyahs, isEmpty);
      },
    );

    test('keeps paused and finished states terminal', () {
      final empty = engine().start(due: const [], now: _now);
      final paused = engine().interrupt(
        engine().start(due: [_record(surahId: 1, ayahNumber: 1)], now: _now),
      );

      expect(engine().next(empty), same(empty));
      expect(engine().onPromptFinished(empty), same(empty));
      expect(engine().interrupt(empty), same(empty));
      expect(engine().grade(paused, HandsFreeGrade.correct), same(paused));
      expect(engine().next(paused), same(paused));
      expect(engine().interrupt(paused), same(paused));
    });
  });

  test('bounds prompt clips between one and three seconds', () {
    expect(
      promptClipLength(const Duration(seconds: 2)),
      const Duration(seconds: 1),
    );
    expect(
      promptClipLength(const Duration(seconds: 10)),
      const Duration(seconds: 3),
    );
    expect(
      promptClipLength(const Duration(milliseconds: 1500)),
      const Duration(seconds: 1),
    );
  });

  test('engine source does not depend on SRS outcome committers', () {
    final source = File(
      'lib/core/memorization/hands_free/hands_free_round_engine.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('review_outcome_committer')));
    expect(source, isNot(contains('srs')));
  });
}
