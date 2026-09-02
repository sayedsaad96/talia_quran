import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';

void main() {
  group('V2RecitationEvaluator', () {
    const evaluator = V2RecitationEvaluator();

    // ── Exact match ─────────────────────────────────────────────────────────

    test(
      'passes with score 1.0 when normalized STT exactly matches target',
      () {
        // Harakat stripped → exact Jaccard 1.0
        final result = evaluator.evaluate(
          targetText: 'مَالِكِ يَوْمِ الدِّينِ',
          spokenText: 'مالك يوم الدين',
        );

        expect(result.passed, isTrue);
        expect(result.similarityScore, 1.0);
        expect(result.assessmentMethod, V2AssessmentMethod.automatic);
        expect(result.normalizedTarget, result.normalizedSpoken);
        expect(result.isNoAttempt, isFalse);
      },
    );

    // ── Similarity tolerance (0.92 threshold) ───────────────────────────────

    test(
      'passes when normalized similarity meets threshold (lenient evaluator)',
      () {
        // Custom low threshold to isolate threshold logic independently.
        // 'مالك الدين' vs 'مالك يوم الدين':
        //   intersection = {مالك, الدين} = 2
        //   union        = {مالك, يوم, الدين} = 3
        //   Jaccard      = 2/3 ≈ 0.667 — above 0.5 but below 0.92
        const lenientEvaluator = V2RecitationEvaluator(
          passThreshold: 0.5,
          retryThreshold: 0.4,
        );
        final result = lenientEvaluator.evaluate(
          targetText: 'بسم الله الرحمن الرحيم',
          spokenText: 'بسم الله الرحمن',
        );

        expect(result.passed, isTrue);
        expect(result.similarityScore, closeTo(0.75, 0.01));
      },
    );

    test('fails when similarity is below 0.88 default threshold', () {
      // 'مالك الدين' vs 'مالك يوم الدين' → ordered similarity 0.67 < 0.88
      final result = evaluator.evaluate(
        targetText: 'مالك يوم الدين',
        spokenText: 'مالك الدين',
      );

      expect(result.passed, isFalse);
      expect(result.similarityScore, closeTo(0.67, 0.01));
      expect(result.isNoAttempt, isFalse);
    });

    test('computes ordered edit similarity for zero-overlap case', () {
      final result = evaluator.evaluate(
        targetText: 'بسم الله الرحمن الرحيم',
        spokenText: 'مالك يوم الدين',
      );

      expect(result.passed, isFalse);
      expect(result.similarityScore, 0.0);
    });

    test('rejects the same words when their Quranic order is changed', () {
      final result = evaluator.evaluate(
        targetText: 'قل هو الله أحد',
        spokenText: 'أحد الله هو قل',
      );

      expect(result.passed, isFalse);
      expect(result.similarityScore, lessThan(kV2PassThreshold));
    });

    test('does not discard repeated words while evaluating recall', () {
      const lenientEvaluator = V2RecitationEvaluator(passThreshold: 0.9);
      final result = lenientEvaluator.evaluate(
        targetText: 'كلا سوف تعلمون ثم كلا سوف تعلمون',
        spokenText: 'كلا سوف تعلمون ثم',
      );

      expect(result.passed, isFalse);
      expect(result.similarityScore, lessThan(0.9));
    });

    test('short ayahs require an exact ordered match', () {
      const lenientEvaluator = V2RecitationEvaluator(
        passThreshold: 0.5,
        retryThreshold: 0.4,
      );
      final result = lenientEvaluator.evaluate(
        targetText: 'مالك يوم الدين',
        spokenText: 'مالك الدين',
      );

      expect(result.passed, isFalse);
      expect(result.verdict, RecitationVerdict.retry);
    });

    test('ambiguous ordered similarity asks for a retry', () {
      final result = evaluator.evaluate(
        targetText: 'بسم الله الرحمن الرحيم',
        spokenText: 'بسم الله الرحمن',
      );

      expect(result.verdict, RecitationVerdict.retry);
    });

    test('low ordered similarity enters remediation', () {
      final result = evaluator.evaluate(
        targetText: 'بسم الله الرحمن الرحيم',
        spokenText: 'مالك يوم الدين',
      );

      expect(result.verdict, RecitationVerdict.remediate);
    });

    // ── No-attempt guard ────────────────────────────────────────────────────

    test('treats whitespace-only spoken text as no attempt', () {
      final result = evaluator.evaluate(
        targetText: 'مالك يوم الدين',
        spokenText: '   ',
      );

      expect(result.isNoAttempt, isTrue);
      expect(result.passed, isFalse);
      expect(result.verdict, RecitationVerdict.technicalUnavailable);
    });

    test('treats fully empty spoken text as no attempt', () {
      final result = evaluator.evaluate(
        targetText: 'مالك يوم الدين',
        spokenText: '',
      );

      expect(result.isNoAttempt, isTrue);
    });

    test('rejects an automatic score on a manual outcome', () {
      expect(
        () => V2RecitationResult(
          passed: true,
          similarityScore: 1.0,
          normalizedTarget: '',
          normalizedSpoken: '',
          assessmentMethod: V2AssessmentMethod.manual,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
