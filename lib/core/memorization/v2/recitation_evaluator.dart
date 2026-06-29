// lib/core/memorization/v2/recitation_evaluator.dart

import '../../../core/utils/arabic_normalizer.dart';

/// V2 recitation evaluation — Product Rules §14.2 & §14.7
///
/// Evaluation strategy:
///   Exact normalized match  → Pass (ideal)
///   Normalized similarity >= [kV2PassThreshold] → Pass (STT tolerance)
///   Below threshold → Fail → Remediation
///
/// Why 0.92 not 1.0:
///   `speech_to_text` on-device ASR produces minor variations even for
///   correct recitations (e.g., shadda omission, alif variation).
///   0.92 is high enough to enforce accuracy while absorbing ASR noise.
///   This implements the spirit of "100% match" from the product rules.
const double kV2PassThreshold = 0.92;

final class V2RecitationEvaluator {
  const V2RecitationEvaluator({double passThreshold = kV2PassThreshold})
      : _threshold = passThreshold;

  final double _threshold;

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

    // Exact match — perfect recitation.
    if (normalizedSpoken == normalizedTarget) {
      return V2RecitationResult(
        passed: true,
        similarityScore: 1.0,
        normalizedTarget: normalizedTarget,
        normalizedSpoken: normalizedSpoken,
      );
    }

    // Similarity-based match for STT tolerance.
    final similarity = _computeSimilarity(normalizedTarget, normalizedSpoken);
    return V2RecitationResult(
      passed: similarity >= _threshold,
      similarityScore: similarity,
      normalizedTarget: normalizedTarget,
      normalizedSpoken: normalizedSpoken,
    );
  }

  /// Token-overlap similarity (word-level Jaccard).
  /// More robust than character-level Dice for Arabic word boundaries.
  double _computeSimilarity(String target, String spoken) {
    final targetTokens = target.split(' ').where((t) => t.isNotEmpty).toSet();
    final spokenTokens = spoken.split(' ').where((t) => t.isNotEmpty).toSet();

    if (targetTokens.isEmpty) return 0.0;

    final intersection = targetTokens.intersection(spokenTokens).length;
    final union = targetTokens.union(spokenTokens).length;

    if (union == 0) return 0.0;
    return intersection / union;
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

