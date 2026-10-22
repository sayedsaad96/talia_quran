import '../../constants/surah_names.dart';
import '../v2/recitation_evaluator.dart';
import '../v2/recitation_word_diff.dart';
import '../v2/session_phase.dart';

/// Ephemeral input resolved from indexed canonical IDs and runtime ayah bodies.
final class SimilarAyahCandidate {
  const SimilarAyahCandidate({required this.key, required this.text});
  final String key;
  final String text;
}

/// Attribution evidence only. This object never contains recognized speech.
final class SimilarAyahConfusionMatch {
  const SimilarAyahConfusionMatch({
    required this.targetKey,
    required this.otherKey,
    required this.originalScore,
    required this.candidateScore,
  });
  final String targetKey;
  final String otherKey;
  final double originalScore;
  final double candidateScore;
}

/// Conservative draft attribution policy, pending human calibration.
///
/// The existing verdict is read only. All indexed neighbors must be supplied;
/// a truncated neighbor list cannot establish an unambiguous alternative.
final class SimilarAyahConfusionDetector {
  const SimilarAyahConfusionDetector();
  static const _margin = 0.15;
  static const _epsilon = 1e-12;

  SimilarAyahConfusionMatch? detect({
    required String targetKey,
    required String spokenText,
    required V2RecitationResult original,
    required Iterable<SimilarAyahCandidate> candidates,
    required bool isAdult,
    required V2SessionPhase phase,
    required bool acceptedFailure,
    V2RecitationEvaluator evaluator = const V2RecitationEvaluator(),
  }) {
    if (!isAdult ||
        !acceptedFailure ||
        phase != V2SessionPhase.reciting ||
        !_validKey(targetKey) ||
        !_eligible(original)) {
      return null;
    }
    final ranked = _rank(targetKey, spokenText, candidates, evaluator);
    if (ranked == null || ranked.isEmpty) return null;
    final best = ranked.first;
    final score = original.similarityScore!;
    if (!best.result.passed ||
        best.score - score + _epsilon < _margin ||
        (ranked.length > 1 &&
            best.score - ranked[1].score + _epsilon < _margin)) {
      return null;
    }
    return SimilarAyahConfusionMatch(
      targetKey: targetKey,
      otherKey: best.key,
      originalScore: score,
      candidateScore: best.score,
    );
  }

  bool _eligible(V2RecitationResult original) {
    final score = original.similarityScore;
    return !original.passed &&
        !original.isNoAttempt &&
        original.assessmentMethod == V2AssessmentMethod.automatic &&
        original.verdict != RecitationVerdict.technicalUnavailable &&
        score != null &&
        score.isFinite &&
        score >= 0 &&
        score <= 1 &&
        original.targetWordCount >= 4 &&
        _wordCount(original.normalizedSpoken) >= 4;
  }

  List<_RankedCandidate>? _rank(
    String targetKey,
    String spokenText,
    Iterable<SimilarAyahCandidate> candidates,
    V2RecitationEvaluator evaluator,
  ) {
    final seen = <String>{};
    final ranked = <_RankedCandidate>[];
    for (final candidate in candidates) {
      if (!_validKey(candidate.key) ||
          candidate.key == targetKey ||
          !seen.add(candidate.key)) {
        return null;
      }
      final result = evaluator.evaluate(
        targetText: candidate.text,
        spokenText: spokenText,
      );
      if (result.targetWordCount < 4 ||
          _wordCount(result.normalizedSpoken) < 4 ||
          result.isNoAttempt) {
        continue;
      }
      ranked.add(_RankedCandidate(candidate.key, result));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  int _wordCount(String normalized) =>
      normalized.split(' ').where(RecitationWordDiffer.isRecitableWord).length;

  bool _validKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return false;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    return surah != null &&
        ayah != null &&
        key == '$surah:$ayah' &&
        surah >= 1 &&
        surah <= 114 &&
        ayah >= 1 &&
        ayah <= SurahNames.ayahCount(surah);
  }
}

final class _RankedCandidate {
  const _RankedCandidate(this.key, this.result);
  final String key;
  final V2RecitationResult result;
  double get score => result.similarityScore!;
}
