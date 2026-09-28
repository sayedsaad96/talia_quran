// lib/core/memorization/v2/recitation_evaluator.dart

import '../../../core/utils/arabic_normalizer.dart';

/// V2 recitation evaluation — Product Rules §14.2 & §14.7
///
/// Evaluation strategy:
///   Exact normalized match  → Pass (ideal)
///   Normalized similarity >= [kV2PassThreshold] → Pass (STT tolerance)
///   Below threshold → Fail → Remediation
///
/// Why 0.88 not 1.0:
///   `speech_to_text` on-device ASR produces minor variations even for
///   correct recitations (e.g., shadda omission, alif variation).
///   0.88 is the initial ordered-match threshold for adult voices.
///   This implements the spirit of "100% match" from the product rules.
const double kV2PassThreshold = 0.88;
const double kV2RetryThreshold = 0.70;

/// Kids-path pass threshold. Child voices are consistently harder for
/// on-device ASR than adult voices (higher pitch, softer consonants, uneven
/// pace), so the kids mission flow evaluates with a more tolerant threshold
/// while still requiring an ordered, near-complete match. Only the kids
/// evaluator/engine instances use this value; the adult path keeps
/// [kV2PassThreshold].
const double kKidsPassThreshold = 0.80;

/// Identifies how a recitation outcome was assessed.
///
/// Manual/self-grade outcomes deliberately have no automatic similarity
/// score. Keeping this marker on the result prevents callers from treating a
/// learner confirmation as speech-recognition evidence.
enum V2AssessmentMethod { automatic, manual }

enum RecitationVerdict { pass, retry, remediate, technicalUnavailable }

final class V2RecitationEvaluator {
  const V2RecitationEvaluator({
    double passThreshold = kV2PassThreshold,
    double retryThreshold = kV2RetryThreshold,
  }) : assert(retryThreshold <= passThreshold),
       _threshold = passThreshold,
       _retryThreshold = retryThreshold;

  final double _threshold;
  final double _retryThreshold;

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
        verdict: RecitationVerdict.pass,
        similarityScore: 1.0,
        normalizedTarget: normalizedTarget,
        normalizedSpoken: normalizedSpoken,
        targetWordCount: _wordCount(normalizedTarget),
        matchedWordCount: _wordCount(normalizedTarget),
      );
    }

    // Short ayahs must be recalled exactly. Longer ayahs use ordered edit
    // similarity, with an explicit retry band rather than a binary failure.
    final similarity = _computeSimilarity(normalizedTarget, normalizedSpoken);
    final targetWordCount = _wordCount(normalizedTarget);
    // Words the child got right, derived from the ordered edit distance the
    // similarity already computes: longest - distance = matched words.
    final matchedWordCount = _matchedWords(normalizedTarget, normalizedSpoken);
    final mayPass = targetWordCount > 3 && similarity >= _threshold;
    final verdict = mayPass
        ? RecitationVerdict.pass
        : similarity >= _retryThreshold
        ? RecitationVerdict.retry
        : RecitationVerdict.remediate;
    return V2RecitationResult(
      passed: verdict == RecitationVerdict.pass,
      verdict: verdict,
      similarityScore: similarity,
      normalizedTarget: normalizedTarget,
      normalizedSpoken: normalizedSpoken,
      targetWordCount: targetWordCount,
      matchedWordCount: matchedWordCount,
    );
  }

  static int _wordCount(String text) =>
      text.split(' ').where((word) => word.isNotEmpty).length;

  /// Ordered-match word count: the longest token chain minus the edit
  /// distance — a child-friendly "you got X of Y words right" metric.
  static int _matchedWords(String target, String spoken) {
    final targetTokens = target.split(' ').where((t) => t.isNotEmpty).toList();
    final spokenTokens = spoken.split(' ').where((t) => t.isNotEmpty).toList();
    if (targetTokens.isEmpty) return 0;
    final distance = _orderedEditDistance(targetTokens, spokenTokens);
    final longest = targetTokens.length > spokenTokens.length
        ? targetTokens.length
        : spokenTokens.length;
    return (longest - distance).clamp(0, targetTokens.length);
  }

  /// Word-level Levenshtein distance preserving order (same DP as
  /// [_computeSimilarity], exposed for the matched-word count).
  static int _orderedEditDistance(List<String> target, List<String> spoken) {
    final previous = List<int>.generate(spoken.length + 1, (i) => i);

    for (var targetIndex = 1; targetIndex <= target.length; targetIndex++) {
      var diagonal = previous[0];
      previous[0] = targetIndex;
      for (var spokenIndex = 1; spokenIndex <= spoken.length; spokenIndex++) {
        final above = previous[spokenIndex];
        final substitutionCost =
            target[targetIndex - 1] == spoken[spokenIndex - 1] ? 0 : 1;
        previous[spokenIndex] = _min3(
          previous[spokenIndex] + 1,
          previous[spokenIndex - 1] + 1,
          diagonal + substitutionCost,
        );
        diagonal = above;
      }
    }

    return previous.last;
  }

  /// Ordered word-edit similarity that preserves order and repeated words.
  double _computeSimilarity(String target, String spoken) {
    final targetTokens = target.split(' ').where((t) => t.isNotEmpty).toList();
    final spokenTokens = spoken.split(' ').where((t) => t.isNotEmpty).toList();

    if (targetTokens.isEmpty) return 0.0;
    final previous = List<int>.generate(spokenTokens.length + 1, (i) => i);

    for (
      var targetIndex = 1;
      targetIndex <= targetTokens.length;
      targetIndex++
    ) {
      var diagonal = previous[0];
      previous[0] = targetIndex;
      for (
        var spokenIndex = 1;
        spokenIndex <= spokenTokens.length;
        spokenIndex++
      ) {
        final above = previous[spokenIndex];
        final substitutionCost =
            targetTokens[targetIndex - 1] == spokenTokens[spokenIndex - 1]
            ? 0
            : 1;
        previous[spokenIndex] = _min3(
          previous[spokenIndex] + 1,
          previous[spokenIndex - 1] + 1,
          diagonal + substitutionCost,
        );
        diagonal = above;
      }
    }

    final distance = previous.last;
    final longest = targetTokens.length > spokenTokens.length
        ? targetTokens.length
        : spokenTokens.length;
    return (1 - (distance / longest)).clamp(0.0, 1.0);
  }

  static int _min3(int first, int second, int third) => first < second
      ? (first < third ? first : third)
      : (second < third ? second : third);
}

/// Result of a single recitation evaluation.
final class V2RecitationResult {
  const V2RecitationResult({
    required this.passed,
    required this.similarityScore,
    required this.normalizedTarget,
    required this.normalizedSpoken,
    this.assessmentMethod = V2AssessmentMethod.automatic,
    RecitationVerdict? verdict,
    this.targetWordCount = 0,
    this.matchedWordCount = 0,
  }) : verdict =
           verdict ??
           (passed ? RecitationVerdict.pass : RecitationVerdict.remediate),
       assert(
         assessmentMethod != V2AssessmentMethod.manual ||
             similarityScore == null,
       ),
       isNoAttempt = false;

  const V2RecitationResult._noAttempt()
    : passed = false,
      similarityScore = 0.0,
      normalizedTarget = '',
      normalizedSpoken = '',
      assessmentMethod = V2AssessmentMethod.automatic,
      verdict = RecitationVerdict.technicalUnavailable,
      targetWordCount = 0,
      matchedWordCount = 0,
      isNoAttempt = true;

  static const noAttempt = V2RecitationResult._noAttempt();

  final bool passed;

  /// Automatic similarity, or `null` for manual/self-grade outcomes.
  final double? similarityScore;
  final String normalizedTarget;
  final String normalizedSpoken;
  final V2AssessmentMethod assessmentMethod;
  final RecitationVerdict verdict;

  /// Total words in the normalized target ayah (0 for no-attempt results).
  final int targetWordCount;

  /// Words the reciter got right in order (0 for no-attempt results) —
  /// the child-friendly "X of Y words" progress feedback.
  final int matchedWordCount;

  /// True if STT returned empty — not counted as a failure.
  final bool isNoAttempt;
}
