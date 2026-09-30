import '../../../../core/memorization/v2/recitation_word_diff.dart';

/// K32 — for each word of the ayah, in order, whether the child recited it.
///
/// One flag per whitespace-separated word of [targetText]. Words the child
/// said beyond the ayah are dropped, and the spoken text itself is never
/// kept — only these flags leave this function.
List<bool> kidsRecalledWords({
  required String targetText,
  required String spokenText,
}) {
  final diff = const RecitationWordDiffer().diff(
    targetText: targetText,
    spokenText: spokenText,
  );
  return [
    for (final word in diff.words)
      if (word.status != RecitationWordStatus.extra)
        word.status == RecitationWordStatus.match,
  ];
}
