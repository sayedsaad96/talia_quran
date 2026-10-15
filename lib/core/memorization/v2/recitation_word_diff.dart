// lib/core/memorization/v2/recitation_word_diff.dart
//
// Pure domain word-alignment diff for V2 recitation results.
// No Flutter imports, no Cubit dependency — unit-testable on its own.

import 'package:equatable/equatable.dart';

import '../../../core/utils/arabic_normalizer.dart';
import 'muqattaat_recitation.dart';

/// How a single word behaved during a recitation attempt.
///
/// [notRecited] marks a written sign of the ayah with no spoken form (a
/// standalone waqf mark, «۞» or «۩»). It keeps its place in the row so the
/// ayah reads as written, and is neither right nor wrong.
enum RecitationWordStatus { match, wrong, missing, extra, notRecited }

/// One word of the rendered comparison row.
final class RecitationWordDiff extends Equatable {
  const RecitationWordDiff({required this.display, required this.status});

  /// The word as it should be shown to the learner: always the target word
  /// (original orthography) for match/wrong/missing/notRecited; the
  /// unexpected spoken word for [extra].
  final String display;

  final RecitationWordStatus status;

  @override
  List<Object?> get props => [display, status];
}

/// Result of aligning the spoken recitation against the target text.
final class RecitationWordDiffResult extends Equatable {
  const RecitationWordDiffResult({required this.words});

  final List<RecitationWordDiff> words;

  int get matchCount =>
      words.where((w) => w.status == RecitationWordStatus.match).length;
  int get wrongCount =>
      words.where((w) => w.status == RecitationWordStatus.wrong).length;
  int get missingCount =>
      words.where((w) => w.status == RecitationWordStatus.missing).length;
  int get extraCount =>
      words.where((w) => w.status == RecitationWordStatus.extra).length;

  bool get isPerfect => wrongCount == 0 && missingCount == 0 && extraCount == 0;

  @override
  List<Object?> get props => [words];
}

/// Computes an ordered word alignment between the target ayah text and the
/// spoken recitation using Levenshtein backtracking, then labels each word so
/// the result sheet can colour-code the learner's attempt.
///
/// Words are compared in their normalized form (mirroring the ordered edit
/// similarity in the recitation evaluator) but the target word is *displayed*
/// in its original orthography, so the learner reads proper Quranic script.
///
/// Levenshtein (not LCS) is used deliberately: substitutions become a single
/// `wrong` word instead of a missing+extra pair, and the DP mirrors the
/// ordered edit distance behind scoring so the visual diff stays consistent
/// with the pass/retry/remediate verdicts.
final class RecitationWordDiffer {
  const RecitationWordDiffer();

  RecitationWordDiffResult diff({
    required String targetText,
    required String spokenText,
  }) {
    final targetTokens = _tokenize(targetText);
    final rawSpokenTokens = _tokenize(spokenText);
    // Disjoint letters («الٓمٓ») are recited by letter name («الف لام ميم»):
    // merge that spoken run into one word so it aligns with the written one.
    final spans = MuqattaatRecitation.collapseSpoken(
      rawTargetTokens: targetTokens,
      normalizedSpokenTokens: rawSpokenTokens.map(_normalizeWord).toList(),
    );
    final spokenTokens = [
      for (final span in spans)
        rawSpokenTokens.sublist(span.start, span.end).join(' '),
    ];

    if (targetTokens.isEmpty && spokenTokens.isEmpty) {
      return const RecitationWordDiffResult(words: []);
    }

    // Compare in normalized space; render the raw (original) tokens. Written
    // signs with no spoken form (standalone waqf marks, «۞», «۩») stay in
    // place for display but never take part in the alignment.
    final normalizedAll = targetTokens.map(_normalizeWord).toList();
    final recitable = [
      for (var i = 0; i < targetTokens.length; i++)
        if (isRecitableWord(normalizedAll[i])) i,
    ];
    final normalizedTarget = [for (final i in recitable) normalizedAll[i]];
    final normalizedSpoken = [for (final span in spans) span.token];

    final alignment = _align(normalizedTarget, normalizedSpoken);
    final words = <RecitationWordDiff>[];
    var nextTargetToken = 0;

    void addTargetWord(int recitableIndex, RecitationWordStatus status) {
      final tokenIndex = recitable[recitableIndex];
      for (; nextTargetToken < tokenIndex; nextTargetToken++) {
        words.add(
          RecitationWordDiff(
            display: targetTokens[nextTargetToken],
            status: RecitationWordStatus.notRecited,
          ),
        );
      }
      words.add(
        RecitationWordDiff(display: targetTokens[tokenIndex], status: status),
      );
      nextTargetToken = tokenIndex + 1;
    }

    for (final (targetIndex, spokenIndex) in alignment) {
      if (targetIndex == null) {
        // Spoken word with no target counterpart.
        words.add(
          RecitationWordDiff(
            display: spokenTokens[spokenIndex!],
            status: RecitationWordStatus.extra,
          ),
        );
      } else if (spokenIndex == null) {
        // Target word the learner did not say.
        addTargetWord(targetIndex, RecitationWordStatus.missing);
      } else {
        addTargetWord(
          targetIndex,
          normalizedTarget[targetIndex] == normalizedSpoken[spokenIndex]
              ? RecitationWordStatus.match
              : RecitationWordStatus.wrong,
        );
      }
    }
    for (; nextTargetToken < targetTokens.length; nextTargetToken++) {
      words.add(
        RecitationWordDiff(
          display: targetTokens[nextTargetToken],
          status: RecitationWordStatus.notRecited,
        ),
      );
    }

    return RecitationWordDiffResult(words: words);
  }

  /// Whether a normalized token is something a reciter says aloud: it holds
  /// at least one letter or digit. Standalone waqf marks normalize to
  /// nothing, and «۞» / «۩» survive normalization but are symbols only.
  static bool isRecitableWord(String normalizedToken) =>
      _letterOrDigit.hasMatch(normalizedToken);

  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Whitespace tokenization of the raw text — keeps original orthography
  /// for display while comparisons go through [ArabicNormalizer].
  List<String> _tokenize(String text) =>
      text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  static String _normalizeWord(String word) =>
      ArabicNormalizer.normalize(word).trim();

  /// Full Levenshtein DP over word tokens + backtracking from the end.
  ///
  /// Returns pairs of (targetIndex | null, spokenIndex | null) in render order.
  /// A diagonal move between unequal words yields a `wrong` substitution pair;
  /// horizontal/vertical moves yield missing/extra singletons.
  List<(int?, int?)> _align(
    List<String> targetTokens,
    List<String> spokenTokens,
  ) {
    final targetLength = targetTokens.length;
    final spokenLength = spokenTokens.length;
    final dp = List.generate(
      targetLength + 1,
      (i) => List<int>.generate(spokenLength + 1, (j) {
        if (i == 0) return j;
        if (j == 0) return i;
        return 0;
      }),
    );
    for (var i = 1; i <= targetLength; i++) {
      for (var j = 1; j <= spokenLength; j++) {
        final substitutionCost = targetTokens[i - 1] == spokenTokens[j - 1]
            ? 0
            : 1;
        dp[i][j] = _min3(
          dp[i - 1][j] + 1, // target word missing from the recitation
          dp[i][j - 1] + 1, // extra spoken word
          dp[i - 1][j - 1] + substitutionCost, // match or substitution
        );
      }
    }

    final reversed = <(int?, int?)>[];
    var i = targetLength;
    var j = spokenLength;
    while (i > 0 || j > 0) {
      if (i > 0 &&
          j > 0 &&
          targetTokens[i - 1] == spokenTokens[j - 1] &&
          dp[i][j] == dp[i - 1][j - 1]) {
        reversed.add((i - 1, j - 1));
        i--;
        j--;
      } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
        reversed.add((i - 1, j - 1)); // substitution → wrong
        i--;
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        reversed.add((i - 1, null)); // missing
        i--;
      } else {
        reversed.add((null, j - 1)); // extra
        j--;
      }
    }
    return reversed.reversed.toList();
  }

  static int _min3(int first, int second, int third) => first < second
      ? (first < third ? first : third)
      : (second < third ? second : third);
}
