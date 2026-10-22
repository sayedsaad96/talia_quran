import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_confusion_detector.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';

void main() {
  const detector = SimilarAyahConfusionDetector();
  const evaluator = V2RecitationEvaluator();
  const target = 'alpha beta gamma delta';
  const spoken = 'one two three four';
  final original = evaluator.evaluate(targetText: target, spokenText: spoken);
  const candidate = SimilarAyahCandidate(key: '2:2', text: spoken);

  SimilarAyahConfusionMatch? detect({
    bool adult = true,
    bool acceptedFailure = true,
    V2SessionPhase phase = V2SessionPhase.reciting,
    V2RecitationResult? evidence,
    List<SimilarAyahCandidate> candidates = const [candidate],
  }) => detector.detect(
    targetKey: '2:1',
    spokenText: spoken,
    original: evidence ?? original,
    candidates: candidates,
    isAdult: adult,
    phase: phase,
    acceptedFailure: acceptedFailure,
  );

  test(
    'identifies a passing alternative without changing original evidence',
    () {
      final before = [
        original.passed,
        original.verdict,
        original.similarityScore,
      ];
      final result = detect();
      expect(result?.targetKey, '2:1');
      expect(result?.otherKey, '2:2');
      expect(result?.candidateScore, 1);
      expect(result?.originalScore, 0);
      expect([
        original.passed,
        original.verdict,
        original.similarityScore,
      ], before);
    },
  );

  test('requires adult, single-ayah reciting and an accepted failure', () {
    expect(detect(adult: false), isNull);
    expect(detect(acceptedFailure: false), isNull);
    for (final phase in V2SessionPhase.values) {
      if (phase != V2SessionPhase.reciting) {
        expect(detect(phase: phase), isNull, reason: phase.name);
      }
    }
  });

  test('excludes passed, manual, no-attempt and technical evidence', () {
    expect(
      detect(
        evidence: evaluator.evaluate(targetText: spoken, spokenText: spoken),
      ),
      isNull,
    );
    expect(detect(evidence: V2RecitationResult.noAttempt), isNull);
    expect(
      detect(
        evidence: const V2RecitationResult(
          passed: false,
          similarityScore: null,
          normalizedTarget: '',
          normalizedSpoken: '',
          assessmentMethod: V2AssessmentMethod.manual,
        ),
      ),
      isNull,
    );
    expect(
      detect(
        evidence: const V2RecitationResult(
          passed: false,
          similarityScore: 0,
          normalizedTarget: target,
          normalizedSpoken: spoken,
          targetWordCount: 4,
          verdict: RecitationVerdict.technicalUnavailable,
        ),
      ),
      isNull,
    );
  });

  test('does not attribute short targets or short alternatives', () {
    expect(
      detect(
        evidence: evaluator.evaluate(
          targetText: 'alpha beta gamma',
          spokenText: spoken,
        ),
      ),
      isNull,
    );
    expect(
      detect(
        candidates: const [
          SimilarAyahCandidate(key: '2:2', text: 'one two three'),
        ],
      ),
      isNull,
    );
    expect(
      detector.detect(
        targetKey: '2:1',
        spokenText: 'one two three',
        original: evaluator.evaluate(
          targetText: target,
          spokenText: 'one two three',
        ),
        candidates: const [candidate],
        isAdult: true,
        phase: V2SessionPhase.reciting,
        acceptedFailure: true,
      ),
      isNull,
    );
  });

  test('requires a passing alternative, not merely a better failure', () {
    expect(
      detect(
        candidates: const [
          SimilarAyahCandidate(key: '2:2', text: 'one two three other'),
        ],
      ),
      isNull,
    );
  });

  test('abstains on ties independently of candidate ordering', () {
    const tied = SimilarAyahCandidate(key: '2:3', text: spoken);
    expect(detect(candidates: const [candidate, tied]), isNull);
    expect(detect(candidates: const [tied, candidate]), isNull);
  });

  test('requires both original and runner-up margins', () {
    const words = 'a b c d e f g h i j';
    final evidence = evaluator.evaluate(
      targetText: 'a b c d e f g x y z',
      spokenText: words,
    );
    SimilarAyahConfusionMatch? ranked(String best, String second) =>
        detector.detect(
          targetKey: '2:1',
          spokenText: words,
          original: evidence,
          candidates: [
            SimilarAyahCandidate(key: '2:2', text: best),
            SimilarAyahCandidate(key: '2:3', text: second),
          ],
          isAdult: true,
          phase: V2SessionPhase.reciting,
          acceptedFailure: true,
        );
    expect(ranked(words, 'a b c d e f g h i x'), isNull);
    expect(ranked(words, 'a b c d e f g h x y')?.otherKey, '2:2');
    final closeOriginal = evaluator.evaluate(
      targetText: 'a b c d e f g h i x',
      spokenText: words,
    );
    // A deliberately stricter original evaluator can fail this 0.9 score.
    final strictOriginal = const V2RecitationEvaluator(
      passThreshold: 1,
    ).evaluate(targetText: 'a b c d e f g h i x', spokenText: words);
    expect(closeOriginal.passed, isTrue);
    expect(
      detector.detect(
        targetKey: '2:1',
        spokenText: words,
        original: strictOriginal,
        candidates: const [SimilarAyahCandidate(key: '2:2', text: words)],
        isAdult: true,
        phase: V2SessionPhase.reciting,
        acceptedFailure: true,
      ),
      isNull,
    );
  });

  test('invalid, self or duplicate candidate identifiers fail closed', () {
    for (final key in ['2:1', '0:1', '2:287', '02:2', '2:2:3']) {
      expect(
        detect(
          candidates: [SimilarAyahCandidate(key: key, text: spoken)],
        ),
        isNull,
        reason: key,
      );
    }
    expect(detect(candidates: const [candidate, candidate]), isNull);
    expect(detect(candidates: const []), isNull);
  });

  test('accepts the exact 0.15 margin without rounding evidence', () {
    final words = List.generate(20, (index) => 'word$index');
    final near = [...words.take(17), 'extra1', 'extra2', 'extra3'].join(' ');
    final spoken = words.join(' ');
    final evidence = evaluator.evaluate(targetText: near, spokenText: spoken);
    expect(evidence.similarityScore, 0.85);
    final result = detector.detect(
      targetKey: '2:1',
      spokenText: spoken,
      original: evidence,
      candidates: [
        SimilarAyahCandidate(key: '2:2', text: spoken),
        SimilarAyahCandidate(key: '2:3', text: near),
      ],
      isAdult: true,
      phase: V2SessionPhase.reciting,
      acceptedFailure: true,
    );
    expect(result?.otherKey, '2:2');
    expect(result?.originalScore, 0.85);
  });

  test('uses the same strict evaluator policy as the active session', () {
    const spoken = 'a b c d e f g h i j';
    const alternative = 'a b c d e f g h i changed';
    final evidence = evaluator.evaluate(
      targetText: 'alpha beta gamma delta',
      spokenText: spoken,
    );
    SimilarAyahConfusionMatch? withPolicy(V2RecitationEvaluator policy) =>
        detector.detect(
          targetKey: '2:1',
          spokenText: spoken,
          original: evidence,
          candidates: const [
            SimilarAyahCandidate(key: '2:2', text: alternative),
          ],
          isAdult: true,
          phase: V2SessionPhase.reciting,
          acceptedFailure: true,
          evaluator: policy,
        );
    expect(withPolicy(evaluator)?.candidateScore, 0.9);
    expect(
      withPolicy(const V2RecitationEvaluator(passThreshold: 0.95)),
      isNull,
    );
  });

  test('rejects nonfinite or out-of-range original evidence', () {
    for (final score in [double.nan, double.infinity, -0.1, 1.1]) {
      expect(
        detect(
          evidence: V2RecitationResult(
            passed: false,
            similarityScore: score,
            normalizedTarget: target,
            normalizedSpoken: spoken,
            targetWordCount: 4,
          ),
        ),
        isNull,
      );
    }
  });
}
