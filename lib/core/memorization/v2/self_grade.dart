/// A learner's own verdict on a recitation checked without speech recognition.
///
/// Self-grades count as real reviews for spaced repetition, but conservatively:
/// they never earn an "excellent" rating, mastery evidence, or certificates.
enum V2SelfGrade {
  /// Recited from memory without difficulty.
  mastered,

  /// Recited, but with noticeable hesitation or small slips.
  hesitated,

  /// Could not recall the ayah — treated as a failed attempt.
  forgot,
}
