import 'package:isar/isar.dart';

part 'isar_review_evidence_event.g.dart';

/// Privacy-safe evidence for one memorization/review task outcome.
///
/// This collection intentionally stores metrics only. Audio recordings, raw
/// speech-recognition output, and Quran text are never valid fields here.
@collection
class IsarReviewEvidenceEvent {
  Id id = Isar.autoIncrement;

  /// Client-generated opaque identifier. A retry may use this key directly.
  @Index(unique: true)
  late String eventId;

  /// Strong local retry fence for this exact event.
  ///
  /// Final task outcomes use `sessionId|taskId|final`; attempts use a stable
  /// sequence key such as `sessionId|taskId|attempt:2`. This deliberately
  /// allows an append-only series of failed attempts while making every retry
  /// of the same logical event idempotent.
  @Index(unique: true)
  late String idempotencyKey;

  @Index()
  late String sessionId;

  late String taskId;
  @Index()
  late String ownerId;
  @Index()
  late String audience;
  late int surahId;
  late int ayahNumber;

  /// [ReviewEvidenceEventType.index].
  late int eventTypeIndex;

  /// [ReviewEvidenceAssessment.index].
  late int assessmentIndex;

  /// [ReviewEvidenceOutcome.index].
  late int outcomeIndex;

  /// [PerformanceRating.index], when a final outcome was scheduled.
  int? ratingIndex;
  double? similarityScore;
  late int attemptCount;
  late int failureCount;
  late int hintLevelIndex;
  late DateTime occurredAt;
  late DateTime committedAt;
  late String studyDayKey;

  /// Auditable list used by privacy regression tests and code review.
  static const persistedFieldNames = <String>[
    'eventId',
    'idempotencyKey',
    'sessionId',
    'taskId',
    'ownerId',
    'audience',
    'surahId',
    'ayahNumber',
    'eventTypeIndex',
    'assessmentIndex',
    'outcomeIndex',
    'ratingIndex',
    'similarityScore',
    'attemptCount',
    'failureCount',
    'hintLevelIndex',
    'occurredAt',
    'committedAt',
    'studyDayKey',
  ];
}

enum ReviewEvidenceAssessment { automatic, manual }

enum ReviewEvidenceEventType { attempt, finalOutcome }

enum ReviewEvidenceOutcome { attempt, passed, failed }
