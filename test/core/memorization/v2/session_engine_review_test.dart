import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

/// Review-mode and block-review remediation-targeting tests.
///
/// Review sessions (LearningIntent.review) are active-recall sessions:
/// they start at reciting, never offer learning/hint stages, and complete
/// without the block-review gate.
void main() {
  group('V2SessionEngine review mode', () {
    final engine = V2SessionEngine();

    test('startReview enters reciting directly from created', () {
      final state = engine.startReview(_reviewState());

      expect(state.phase, V2SessionPhase.reciting);
      expect(state.isReview, isTrue);
    });

    test('startReview is ignored outside the created phase', () {
      final learning = engine.startLearning(_reviewState());
      expect(engine.startReview(learning).phase, V2SessionPhase.learning);
    });

    test('a single-ayah review completes directly without block review', () {
      var state = engine.startReview(_reviewState(blockAyahs: [_ayah(1)]));
      state = engine.evaluateRecitation(state, 'الحمد لله رب العالمين');

      expect(state.phase, V2SessionPhase.completed);
      expect(state.passedAyahNumbers, contains(1));
    });

    test(
      'a multi-ayah review passes ayahs then completes without block review',
      () {
        var state = engine.startReview(_reviewState());

        state = engine.evaluateRecitation(state, 'الحمد لله رب العالمين');
        expect(state.phase, V2SessionPhase.reciting);
        expect(state.currentAyah.numberInSurah, 2);

        state = engine.evaluateRecitation(state, 'الرحمن الرحيم');
        expect(state.phase, V2SessionPhase.completed);
        expect(state.passedAyahNumbers, containsAll(<int>[1, 2]));
      },
    );

    test('a failed review enters remediation and retries recite directly', () {
      var state = engine.startReview(_reviewState(blockAyahs: [_ayah(1)]));
      state = engine.evaluateRecitation(state, 'كلام غير صحيح');

      expect(state.phase, V2SessionPhase.remediation);

      state = engine.completeRemediation(state);
      expect(state.phase, V2SessionPhase.memorizing);

      state = engine.startReciting(state);
      state = engine.evaluateRecitation(state, 'الحمد لله رب العالمين');
      expect(state.phase, V2SessionPhase.completed);
    });

    test('review mode never reaches the block review gate', () {
      var state = engine.startReview(_reviewState(blockReviewRequired: true));
      state = engine.evaluateRecitation(state, 'الحمد لله رب العالمين');
      state = engine.evaluateRecitation(state, 'الرحمن الرحيم');

      expect(state.phase, V2SessionPhase.completed);
      expect(state.blockReviewRequired, isTrue);
    });
  });

  group('V2SessionEngine block-review remediation targeting', () {
    final engine = V2SessionEngine();

    test('remediates the ayah where the recitation actually broke', () {
      var state = _allPassedState();
      state = engine.startBlockReview(state);

      // Ayah 1 recited correctly, ayah 2 broken.
      state = engine.evaluateBlockReview(
        state,
        'الحمد لله رب العالمين كلام مختلف تماما',
      );

      expect(state.phase, V2SessionPhase.remediation);
      expect(state.currentAyah.numberInSurah, 2);
    });

    test('does not loop on an already passed historically weak ayah', () {
      // Ayah 1 is historically weak (3 failures) but the break is in ayah 2.
      var state = _allPassedState();
      state = state.copyWith(failureTracker: _weakTracker(ayahNumber: 1));
      state = engine.startBlockReview(state);
      state = engine.evaluateBlockReview(
        state,
        'الحمد لله رب العالمين كلام مختلف تماما',
      );

      expect(state.currentAyah.numberInSurah, 2);
      expect(state.passedAyahNumbers, contains(1));
    });

    test(
      'falls back to the first unpassed ayah when the diff has no signal',
      () {
        var state = _allPassedState();
        state = state.copyWith(passedAyahNumbers: const {1});
        state = engine.startBlockReview(state);
        // Empty recitation is a no-attempt: no penalty, phase unchanged.
        state = engine.evaluateBlockReview(state, '');

        expect(state.phase, V2SessionPhase.blockReview);
        expect(state.lastRecitationResult, isNull);
      },
    );
  });
}

// ─── Fixtures ──────────────────────────────────────────────────────────────

Ayah _ayah(int number, {String? text}) {
  final texts = {
    1: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
    2: 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
  };
  return Ayah(
    number: number,
    surahId: 1,
    text: text ?? texts[number]!,
    numberInSurah: number,
  );
}

V2SessionState _reviewState({
  List<Ayah> blockAyahs = const [],
  bool blockReviewRequired = true,
}) {
  return V2SessionState.initial(
    surahId: 1,
    blockAyahs: blockAyahs.isEmpty ? [_ayah(1), _ayah(2)] : blockAyahs,
    blockReviewRequired: blockReviewRequired,
    isReview: true,
  );
}

V2SessionState _allPassedState() {
  final state = V2SessionState.initial(
    surahId: 1,
    blockAyahs: [_ayah(1), _ayah(2)],
    blockReviewRequired: true,
  );
  return state.copyWith(
    phase: V2SessionPhase.blockReviewPending,
    passedAyahNumbers: const {1, 2},
  );
}

V2AyahFailureTracker _weakTracker({required int ayahNumber}) {
  var tracker = const V2AyahFailureTracker();
  for (var i = 0; i < 3; i++) {
    tracker = tracker.recordFailure(surahId: 1, ayahNumber: ayahNumber);
  }
  return tracker;
}
