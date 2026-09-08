import '../../../../core/memorization/review_mastery_policy.dart';
import '../models/isar_review_evidence_event.dart';
import '../../domain/entities/memorization_entities.dart';

/// Derives the conservative mastery projection from append-only evidence.
abstract final class ReviewMasteryEvidenceBuilder {
  static ReviewMasteryEvidence fromEvents({
    required int strengthLevel,
    required Iterable<IsarReviewEvidenceEvent> events,
  }) {
    final ordered = events.toList()
      ..sort((a, b) => a.committedAt.compareTo(b.committedAt));
    final automaticDays = ordered
        .where(_isAutomaticFinalPass)
        .map((event) => event.studyDayKey)
        .toSet();
    final latest = ordered.isEmpty ? null : ordered.last;
    return ReviewMasteryEvidence(
      strengthLevel: strengthLevel,
      automaticSuccessStudyDays: automaticDays,
      lastAssessmentWasManual:
          latest?.assessmentIndex == ReviewEvidenceAssessment.manual.index,
      lastOutcomeWasWeak: latest?.ratingIndex == PerformanceRating.weak.index,
    );
  }

  static bool _isAutomaticFinalPass(IsarReviewEvidenceEvent event) {
    return event.eventTypeIndex == ReviewEvidenceEventType.finalOutcome.index &&
        event.assessmentIndex == ReviewEvidenceAssessment.automatic.index &&
        event.outcomeIndex == ReviewEvidenceOutcome.passed.index;
  }
}
