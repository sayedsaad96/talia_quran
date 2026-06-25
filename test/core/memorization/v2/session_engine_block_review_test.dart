import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  group('V2SessionEngine block review', () {
    late V2SessionEngine engine;

    setUp(() {
      engine = V2SessionEngine();
    });

    test('block review success completes the session', () {
      var state = _stateWithAllAyahsPassed();

      state = engine.startBlockReview(state);
      state = engine.evaluateBlockReview(
        state,
        'الحمد لله رب العالمين الرحمن الرحيم',
      );

      expect(state.phase, V2SessionPhase.completed);
      expect(state.lastRecitationResult?.passed, isTrue);
    });

    test('block review failure enters remediation and never completes', () {
      var state = _stateWithAllAyahsPassed();

      state = engine.startBlockReview(state);
      state = engine.evaluateBlockReview(state, 'wrong text');

      expect(state.phase, V2SessionPhase.remediation);
      expect(state.phase, isNot(V2SessionPhase.completed));
      expect(state.lastRecitationResult?.passed, isFalse);
      expect(state.failureTracker.totalFailures, 1);
    });

    test(
      'remediation after block review failure targets one affected ayah',
      () {
        var state = _stateWithAllAyahsPassed();

        state = engine.startBlockReview(state);
        state = engine.evaluateBlockReview(state, 'wrong text');

        expect(state.currentAyah.numberInSurah, 1);
        expect(state.failureTracker.failureCountFor(1, 1), 1);
        expect(state.failureTracker.failureCountFor(1, 2), 0);

        state = engine.completeRemediation(state);

        expect(state.phase, V2SessionPhase.memorizing);
        expect(state.currentAyah.numberInSurah, 1);
      },
    );

    test('retry block review after remediation can complete', () {
      var state = _stateWithAllAyahsPassed();

      state = engine.startBlockReview(state);
      state = engine.evaluateBlockReview(state, 'wrong text');
      state = engine.completeRemediation(state);
      state = engine.startReciting(state);
      state = engine.evaluateRecitation(state, 'الحمد لله رب العالمين');

      expect(state.phase, V2SessionPhase.blockReviewPending);
      expect(state.passedAyahNumbers, containsAll(<int>[1, 2]));

      state = engine.startBlockReview(state);
      state = engine.evaluateBlockReview(
        state,
        'الحمد لله رب العالمين الرحمن الرحيم',
      );

      expect(state.phase, V2SessionPhase.completed);
    });

    test('passed ayahs remain passed after block review failure', () {
      var state = _stateWithAllAyahsPassed();
      final passedBefore = state.passedAyahNumbers;

      state = engine.startBlockReview(state);
      state = engine.evaluateBlockReview(state, 'wrong text');

      expect(state.passedAyahNumbers, passedBefore);
      expect(state.passedAyahNumbers, containsAll(<int>[1, 2]));
    });

    test('failed block review has no hidden auto-completion path', () {
      var state = _stateWithAllAyahsPassed();

      state = engine.startBlockReview(state);
      for (var i = 0; i < 3; i++) {
        state = engine.evaluateBlockReview(state, 'wrong text');
        expect(state.phase, V2SessionPhase.remediation);
        state = engine.completeRemediation(state);
        state = engine.startReciting(state);
        state = engine.evaluateRecitation(state, state.currentAyah.text);
        expect(state.phase, V2SessionPhase.blockReviewPending);
        state = engine.startBlockReview(state);
      }
    });

    test('no-attempt STT keeps block review active without penalty', () {
      var state = _stateWithAllAyahsPassed();

      state = engine.startBlockReview(state);
      state = engine.evaluateBlockReview(state, '   ');

      expect(state.phase, V2SessionPhase.blockReview);
      expect(state.failureTracker.totalFailures, 0);
      expect(state.lastRecitationResult, isNull);
    });

    test('resume model preserves block review phase', () {
      final saved = IsarV2Session.create(
        surahId: 1,
        blockAyahNumbers: const [1, 2],
        currentAyahIndex: 0,
        phaseIndex: V2SessionPhase.blockReview.index,
        passedAyahNumbers: const {1, 2},
        failureCounts: const {},
        hintLevels: const {},
        blockReviewRequired: true,
      );

      expect(saved.phaseIndex, V2SessionPhase.blockReview.index);
      expect(
        V2SessionPhase.values[saved.phaseIndex],
        V2SessionPhase.blockReview,
      );
      expect(saved.passedAyahNumbers, containsAll(<int>[1, 2]));
    });
  });
}

V2SessionState _stateWithAllAyahsPassed() {
  var state = V2SessionState.initial(
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
    blockReviewRequired: true,
  );
  final engine = V2SessionEngine();
  state = engine.startLearning(state);
  state = engine.startMemorizing(state);
  state = engine.startReciting(state);
  state = engine.evaluateRecitation(state, 'الحمد لله رب العالمين');
  state = engine.startMemorizing(state);
  state = engine.startReciting(state);
  return engine.evaluateRecitation(state, 'الرحمن الرحيم');
}
