import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/utils/arabic_normalizer.dart';

void main() {
  group('STT normalization compliance', () {
    const evaluator = V2RecitationEvaluator();

    test('normalizes target and STT input before pass/fail evaluation', () {
      const targetText = 'أَإِآ ٱلرَّحْمَٰنِۖ هَٰذَا؟ بِئْرٌ';
      const spokenText = 'ااا الرحمن هذا بير!';
      const expectedNormalized = 'ااا الرحمان هاذا بير';

      final result = evaluator.evaluate(
        targetText: targetText,
        spokenText: spokenText,
      );

      expect(ArabicNormalizer.normalize(targetText), expectedNormalized);
      expect(ArabicNormalizer.normalize(spokenText), expectedNormalized);
      expect(result.normalizedTarget, expectedNormalized);
      expect(result.normalizedSpoken, expectedNormalized);
      expect(result.passed, isTrue);
      expect(result.similarityScore, 1.0);
    });
  });
}
