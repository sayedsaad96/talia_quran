/// Privacy-safe projection of the evidence needed to call an ayah memorized.
final class ReviewMasteryEvidence {
  const ReviewMasteryEvidence({
    required this.strengthLevel,
    required this.automaticSuccessStudyDays,
    required this.lastAssessmentWasManual,
    required this.lastOutcomeWasWeak,
  });

  final int strengthLevel;
  final Set<String> automaticSuccessStudyDays;
  final bool lastAssessmentWasManual;
  final bool lastOutcomeWasWeak;
}

/// Conservative product definition of verified memorization.
abstract final class ReviewMasteryPolicy {
  static const int minimumStrength = 6;
  static const int requiredAutomaticStudyDays = 3;

  static bool isMemorized(ReviewMasteryEvidence evidence) {
    return evidence.strengthLevel >= minimumStrength &&
        evidence.automaticSuccessStudyDays.length >=
            requiredAutomaticStudyDays &&
        !evidence.lastAssessmentWasManual &&
        !evidence.lastOutcomeWasWeak;
  }
}
