import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  group('V2SessionEngine', () {
    late V2SessionEngine engine;

    setUp(() {
      engine = V2SessionEngine();
    });

    test('runs per-ayah flow before block review', () {
      var state = _initialState(blockReviewRequired: true);

      state = engine.startLearning(state);
      state = engine.startMemorizing(state);
      state = engine.startReciting(state);
      state = engine.evaluateRecitation(state, 'الحمد لله رب العالمين');

      expect(state.phase, V2SessionPhase.learning);
      expect(state.currentAyah.numberInSurah, 2);
      expect(state.passedAyahNumbers, contains(1));

      state = engine.startMemorizing(state);
      state = engine.startReciting(state);
      state = engine.evaluateRecitation(state, 'الرحمن الرحيم');

      expect(state.phase, V2SessionPhase.blockReviewPending);
      expect(state.passedAyahNumbers, containsAll(<int>[1, 2]));
    });

    test('requires block review pass before completion when configured', () {
      var state = _stateWithAllAyahsPassed(blockReviewRequired: true);

      state = engine.startBlockReview(state);
      state = engine.evaluateBlockReview(
        state,
        'الحمد لله رب العالمين الرحمن الرحيم',
      );

      expect(state.phase, V2SessionPhase.completed);
    });

    test('skips block review only when configured off', () {
      var state = _initialState(blockReviewRequired: false);

      state = engine.startLearning(state);
      state = engine.startMemorizing(state);
      state = engine.startReciting(state);
      state = engine.evaluateRecitation(state, 'الحمد لله رب العالمين');
      state = engine.startMemorizing(state);
      state = engine.startReciting(state);
      state = engine.evaluateRecitation(state, 'الرحمن الرحيم');

      expect(state.phase, V2SessionPhase.completed);
    });

    test('records hints only during memorizing phase', () {
      var state = engine.startLearning(_initialState());

      state = engine.useHint(state, V2HintLevel.firstWord);
      expect(state.hintTracker.hasAnyHint, isFalse);

      state = engine.startMemorizing(state);
      state = engine.useHint(state, V2HintLevel.firstWord);

      expect(state.hintTracker.levelFor(1, 1), V2HintLevel.firstWord);
    });

    test('ignores invalid phase transitions without changing state', () {
      final created = _initialState();

      expect(engine.startMemorizing(created).phase, V2SessionPhase.created);
      expect(engine.startReciting(created).phase, V2SessionPhase.created);
      expect(
        engine.evaluateRecitation(created, 'text').phase,
        V2SessionPhase.created,
      );
      expect(
        engine.startBlockReview(created).phase,
        V2SessionPhase.created,
      );
      expect(
        engine.evaluateBlockReview(created, 'text').phase,
        V2SessionPhase.created,
      );
      expect(
        engine.completeRemediation(created).phase,
        V2SessionPhase.created,
      );
    });

    test('escalates an ayah to weak after three failed recitations', () {
      var state = engine.startLearning(_initialState());
      state = engine.startMemorizing(state);

      for (var i = 0; i < kWeakAyahFailureThreshold; i++) {
        state = engine.startReciting(state);
        state = engine.evaluateRecitation(state, 'wrong text');
        if (i < kWeakAyahFailureThreshold - 1) {
          state = engine.completeRemediation(state);
        }
      }

      expect(state.phase, V2SessionPhase.remediation);
      expect(state.failureTracker.failureCountFor(1, 1), 3);
      expect(state.failureTracker.isWeak(1, 1), isTrue);
      expect(
        state.failureTracker.remediationLevelFor(1, 1),
        V2RemediationLevel.weakAyah,
      );
    });
  });
}

V2SessionState _initialState({bool blockReviewRequired = true}) {
  return V2SessionState.initial(
    surahId: 1,
    blockAyahs: const [
      Ayah(
        number: 1,
        surahId: 1,
        text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
        numberInSurah: 1,
      ),
      Ayah(
        number: 2,
        surahId: 1,
        text: 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        numberInSurah: 2,
      ),
    ],
    blockReviewRequired: blockReviewRequired,
  );
}

V2SessionState _stateWithAllAyahsPassed({required bool blockReviewRequired}) {
  var state = _initialState(blockReviewRequired: blockReviewRequired);
  state = V2SessionEngine().startLearning(state);
  state = V2SessionEngine().startMemorizing(state);
  state = V2SessionEngine().startReciting(state);
  state = V2SessionEngine().evaluateRecitation(state, 'الحمد لله رب العالمين');
  state = V2SessionEngine().startMemorizing(state);
  state = V2SessionEngine().startReciting(state);
  return V2SessionEngine().evaluateRecitation(state, 'الرحمن الرحيم');
}
