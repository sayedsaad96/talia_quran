import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

/// A5 — a near miss (similarity in the retry band) is often a speech
/// recognition slip, not a memorization failure. It earns another attempt
/// without failure evidence, up to a small limit.
void main() {
  final engine = V2SessionEngine();
  // Three of four words: similarity 0.75, inside the 0.70–0.88 retry band.
  const nearMiss = 'الحمد لله رب';

  V2SessionState reciting() {
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
      blockReviewRequired: false,
    );
    state = engine.startLearning(state);
    state = engine.startMemorizing(state);
    return engine.startReciting(state);
  }

  test('a near miss stays in reciting without recording a failure', () {
    final state = engine.evaluateRecitation(reciting(), nearMiss);

    expect(state.phase, V2SessionPhase.reciting);
    expect(state.failureTracker.totalFailures, 0);
    expect(state.lastRecitationResult?.verdict, RecitationVerdict.retry);
    expect(state.nearMissCount, 1);
  });

  test('repeated near misses fall back to remediation after the limit', () {
    var state = reciting();
    for (var i = 0; i < V2SessionEngine.maxNearMisses; i++) {
      state = engine.evaluateRecitation(state, nearMiss);
      expect(state.phase, V2SessionPhase.reciting);
    }

    state = engine.evaluateRecitation(state, nearMiss);

    expect(state.phase, V2SessionPhase.remediation);
    expect(state.failureTracker.failureCountFor(1, 1), 1);
    expect(state.lastRecitationResult?.verdict, RecitationVerdict.remediate);
    expect(state.nearMissCount, 0);
  });

  test('a pass after a near miss resets the allowance for the next ayah', () {
    var state = engine.evaluateRecitation(reciting(), nearMiss);
    state = engine.evaluateRecitation(state, 'الحمد لله رب العالمين');

    expect(state.passedAyahNumbers, contains(1));
    expect(state.nearMissCount, 0);
  });

  test(
    'a challenging plan recites against a stricter pass threshold (M-U4)',
    () {
      // Neutral fixture words (not Quran text): 9 of 10 correct = 0.90.
      const target = 'كتاب قلم بيت شجر نهر جبل سماء ارض بحر نور';
      const spoken = 'كتاب قلم بيت شجر نهر جبل سماء ارض بحر';
      V2SessionState start(V2SessionEngine e) {
        var state = V2SessionState.initial(
          surahId: 1,
          blockAyahs: const [
            Ayah(number: 1, surahId: 1, text: target, numberInSurah: 1),
          ],
          blockReviewRequired: false,
        );
        state = e.startLearning(state);
        state = e.startMemorizing(state);
        return e.startReciting(state);
      }

      final normal = V2SessionEngine();
      final strict = normal.withPassThreshold(0.92);

      expect(
        normal.evaluateRecitation(start(normal), spoken).passedAyahNumbers,
        contains(1),
      );
      final strictResult = strict.evaluateRecitation(start(strict), spoken);
      expect(strictResult.passedAyahNumbers, isEmpty);
      expect(
        strictResult.lastRecitationResult?.verdict,
        RecitationVerdict.retry,
      );
    },
  );
}
