// lib/core/memorization/v2/recitation_evaluator.dart

import '../../../core/utils/arabic_normalizer.dart';

/// V2 recitation evaluation — Product Rules §14.2 & §14.7
///
/// Evaluation strategy:
///   Exact normalized match → Pass
///   Any normalized mismatch → Fail → Remediation
const double kV2PassThreshold = 1.0;

final class V2RecitationEvaluator {
  const V2RecitationEvaluator({double passThreshold = kV2PassThreshold});

  /// Evaluates a single ayah recitation.
  ///
  /// Returns [V2RecitationResult] with pass/fail and similarity score.
  /// Empty [spokenText] is treated as no-attempt — returns [V2RecitationResult.noAttempt].
  V2RecitationResult evaluate({
    required String targetText,
    required String spokenText,
  }) {
    final normalizedTarget = ArabicNormalizer.normalize(targetText);
    final normalizedSpoken = ArabicNormalizer.normalize(spokenText);

    // No-attempt guard — do not count empty STT as failure.
    if (normalizedSpoken.isEmpty) {
      return V2RecitationResult.noAttempt;
    }

    return V2RecitationResult(
      passed: normalizedSpoken == normalizedTarget,
      similarityScore: normalizedSpoken == normalizedTarget ? 1.0 : 0.0,
      normalizedTarget: normalizedTarget,
      normalizedSpoken: normalizedSpoken,
    );
  }
}

/// Result of a single recitation evaluation.
final class V2RecitationResult {
  const V2RecitationResult({
    required this.passed,
    required this.similarityScore,
    required this.normalizedTarget,
    required this.normalizedSpoken,
  }) : isNoAttempt = false;

  const V2RecitationResult._noAttempt()
    : passed = false,
      similarityScore = 0.0,
      normalizedTarget = '',
      normalizedSpoken = '',
      isNoAttempt = true;

  static const noAttempt = V2RecitationResult._noAttempt();

  final bool passed;
  final double similarityScore;
  final String normalizedTarget;
  final String normalizedSpoken;

  /// True if STT returned empty — not counted as a failure.
  final bool isNoAttempt;
}
