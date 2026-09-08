import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/review_mastery_policy.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';
import 'package:talia_quran/features/memorization_plus/data/services/review_mastery_evidence_builder.dart';

void main() {
  group('ReviewMasteryPolicy', () {
    test('derives study-day evidence from automatic final outcomes only', () {
      final events = [
        _event(day: '2026-09-01'),
        _event(day: '2026-09-03'),
        _event(day: '2026-09-08'),
        _event(day: '2026-09-08', manual: true),
      ];

      final evidence = ReviewMasteryEvidenceBuilder.fromEvents(
        strengthLevel: 6,
        events: events,
      );

      expect(ReviewMasteryPolicy.isMemorized(evidence), isFalse);
      expect(evidence.automaticSuccessStudyDays, hasLength(3));
      expect(evidence.lastAssessmentWasManual, isTrue);
    });
    test('requires three distinct automatic study days after strength six', () {
      const evidence = ReviewMasteryEvidence(
        strengthLevel: 6,
        automaticSuccessStudyDays: {
          '2026-09-01',
          '2026-09-03',
          '2026-09-08',
        },
        lastAssessmentWasManual: false,
        lastOutcomeWasWeak: false,
      );

      expect(ReviewMasteryPolicy.isMemorized(evidence), isTrue);
    });

    test('does not certify self-assessment or a weak final outcome', () {
      const selfAssessment = ReviewMasteryEvidence(
        strengthLevel: 8,
        automaticSuccessStudyDays: {
          '2026-09-01',
          '2026-09-03',
          '2026-09-08',
        },
        lastAssessmentWasManual: true,
        lastOutcomeWasWeak: false,
      );
      const weakOutcome = ReviewMasteryEvidence(
        strengthLevel: 8,
        automaticSuccessStudyDays: {
          '2026-09-01',
          '2026-09-03',
          '2026-09-08',
        },
        lastAssessmentWasManual: false,
        lastOutcomeWasWeak: true,
      );

      expect(ReviewMasteryPolicy.isMemorized(selfAssessment), isFalse);
      expect(ReviewMasteryPolicy.isMemorized(weakOutcome), isFalse);
    });
  });
}

IsarReviewEvidenceEvent _event({required String day, bool manual = false}) {
  return IsarReviewEvidenceEvent()
    ..eventId = 'event-$day-$manual'
    ..idempotencyKey = 'session|$day|$manual'
    ..sessionId = 'session'
    ..taskId = 'task'
    ..ownerId = 'owner'
    ..audience = 'adult'
    ..surahId = 1
    ..ayahNumber = 1
    ..eventTypeIndex = ReviewEvidenceEventType.finalOutcome.index
    ..assessmentIndex =
        (manual
                ? ReviewEvidenceAssessment.manual
                : ReviewEvidenceAssessment.automatic)
            .index
    ..outcomeIndex = ReviewEvidenceOutcome.passed.index
    ..attemptCount = 1
    ..failureCount = 0
    ..hintLevelIndex = 0
    ..occurredAt = DateTime.utc(2026, 9, 8)
    ..committedAt = DateTime.utc(2026, 9, 8)
    ..studyDayKey = day;
}
