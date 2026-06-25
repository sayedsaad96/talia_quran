import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';

void main() {
  group('V2RecitationEvaluator', () {
    const evaluator = V2RecitationEvaluator();

    test('passes only when normalized STT exactly matches target text', () {
      final result = evaluator.evaluate(
        targetText: 'مَالِكِ يَوْمِ الدِّينِ',
        spokenText: 'مالك يوم الدين',
      );

      expect(result.passed, isTrue);
      expect(result.similarityScore, 1.0);
      expect(result.normalizedTarget, result.normalizedSpoken);
    });

    test('fails normalized near matches even when most words overlap', () {
      final result = evaluator.evaluate(
        targetText: 'مالك يوم الدين',
        spokenText: 'مالك الدين',
      );

      expect(result.passed, isFalse);
      expect(result.similarityScore, 0.0);
      expect(result.normalizedTarget, isNot(result.normalizedSpoken));
    });

    test('treats empty recognized text as no attempt', () {
      final result = evaluator.evaluate(
        targetText: 'مالك يوم الدين',
        spokenText: '   ',
      );

      expect(result.isNoAttempt, isTrue);
      expect(result.passed, isFalse);
    });
  });
}
