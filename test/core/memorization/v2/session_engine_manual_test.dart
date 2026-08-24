import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

/// V1-M8 — manual/self-grade route: a learner must be able to complete
/// memorization when STT is unavailable (mic denied, recognizer missing,
/// airplane mode) without any automatic score being fabricated.
void main() {
  late V2SessionEngine engine;

  setUp(() {
    engine = V2SessionEngine();
  });

  group('submitManualRecall', () {
    test('marks the current ayah passed and advances like an automatic pass',
        () {
      var state = _initialState(blockReviewRequired: false);
      state = engine.startLearning(state);
      state = engine.startMemorizing(state);
      state = engine.startReciting(state);

      state = engine.submitManualRecall(state);

      expect(state.passedAyahNumbers, contains(1));
      expect(state.phase, V2SessionPhase.learning);
      expect(
        state.failureTracker.failureCountFor(1, 1),
        0,
        reason: 'a self-graded pass must never be recorded as a failure',
      );
    });

    test('completes the session when the last ayah passes manually', () {
      var state = _initialState(blockReviewRequired: true);

      state = engine.startLearning(state);
      state = engine.startMemorizing(state);
      state = engine.startReciting(state);
      state = engine.submitManualRecall(state);

      state = engine.startMemorizing(state);
      state = engine.startReciting(state);
      state = engine.submitManualRecall(state);

      expect(state.passedAyahNumbers, containsAll(<int>[1, 2]));
      expect(state.phase, V2SessionPhase.blockReviewPending);
    });

    test('is ignored outside the reciting phase', () {
      final created = _initialState();
      expect(engine.submitManualRecall(created), same(created));
    });
  });

  group('submitManualBlockReview', () {
    test('completes the session from the block review phase', () {
      var state = _stateWithAllAyahsPassed(blockReviewRequired: true);
      state = engine.startBlockReview(state);

      state = engine.submitManualBlockReview(state);

      expect(state.phase, V2SessionPhase.completed);
      expect(state.lastRecitationResult?.passed, isTrue);
    });

    test('is ignored outside the block review phase', () {
      final created = _initialState();
      expect(engine.submitManualBlockReview(created), same(created));
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
