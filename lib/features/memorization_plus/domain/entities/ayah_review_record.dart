import 'package:equatable/equatable.dart';

import '../../../../core/memorization/review_classification.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum PerformanceRating { excellent, average, weak }

/// Identifies the originating write path for an [AyahReviewRecord].
///
/// Used to safely separate adult and kids memorization records that share the
/// same Isar collection.  New records receive an explicit tag at the write site;
/// records that existed before this field was introduced are treated as
/// [unknown] (their `createdByModeIndex` is `null` in Isar).
enum ReviewRecordCreatedByMode {
  /// Written by the Adult MemPlus path (V2 session or quiz flows).
  adultMemPlus,

  /// Written by Kids Gamified via the V2 session engine/review adapter.
  kidsMode,

  /// Reserved for future Hifz SRS integration.
  hifz,

  /// Written during SharedPreferences → Isar migration; source is ambiguous.
  migration,

  /// Existing records that predate source-metadata tagging.
  unknown,

  /// Created by a Memorization V2 session (MemorizationSessionCubit).
  /// Treated as adult-compatible for Smart Coach and Quiz filtering.
  v2Session,
}

enum ReviewState {
  newCard,
  learning,
  review,
  relearning,
}

// ─── AyahReviewRecord ─────────────────────────────────────────────────────────

/// Enhanced per-ayah progress record used exclusively by MemorizationPlus.
/// Lives alongside existing [AyahProgress] without replacing it.
class AyahReviewRecord extends Equatable {
  const AyahReviewRecord({
    required this.surahId,
    required this.ayahNumber,
    required this.strengthLevel,
    required this.intervalDays,
    required this.lastReviewedAt,
    required this.nextReviewDate,
    required this.totalReviews,
    required this.lastRating,
    this.easeFactor = 2.5,
    this.lapses = 0,
    this.difficulty = 5.0,
    this.stability = 0.0,
    this.reviewState = ReviewState.newCard,
    this.createdByMode = ReviewRecordCreatedByMode.unknown,
    this.predictedRetrievability,
    this.predictedFsrsIntervalDays,
    this.predictedFsrsDueDate,
    this.predictedRecallProbability,
    this.schedulerVsFsrsGapDays,
    this.schedulerVsFsrsRatio,
    this.schedulerEarlierThanFsrs,
  });

  final int surahId;
  final int ayahNumber;

  /// 0 = new, 1–5 = weak→strong, 6+ = memorized
  final int strengthLevel;

  /// Current interval in days
  final int intervalDays;

  final DateTime lastReviewedAt;
  final DateTime nextReviewDate;
  final int totalReviews;
  final PerformanceRating? lastRating;

  /// SM-2 derived multiplier for the next interval
  final double easeFactor;

  /// Number of times this ayah was rated as weak after being reviewed
  final int lapses;

  /// FSRS: Current difficulty level
  final double difficulty;

  /// FSRS: Memory stability (in days)
  final double stability;

  /// FSRS: Current state of the card
  final ReviewState reviewState;

  /// Preparation for future leech detection (lapses >= 8)
  bool get isLeech => lapses >= 8;

  /// Source metadata added in Sprint 7B. Records written before this field
  /// was introduced default to [ReviewRecordCreatedByMode.unknown].
  final ReviewRecordCreatedByMode createdByMode;

  /// FSRS: Shadow predicted retrievability
  final double? predictedRetrievability;

  /// FSRS: Shadow predicted interval
  final int? predictedFsrsIntervalDays;

  /// FSRS: Shadow predicted next review date
  final DateTime? predictedFsrsDueDate;

  /// FSRS: Future shadow probability of recall
  final double? predictedRecallProbability;

  /// FSRS Analytics: Gap in days between FSRS predicted interval and Scheduler interval
  final int? schedulerVsFsrsGapDays;

  /// FSRS Analytics: Ratio of FSRS predicted interval to Scheduler interval
  final double? schedulerVsFsrsRatio;

  /// FSRS Analytics: True if Scheduler interval is strictly less than FSRS interval
  final bool? schedulerEarlierThanFsrs;

  ReviewClassification get reviewClassification =>
      const ReviewClassifier().classify(
        ReviewClassificationInput(
          now: DateTime.now().toUtc(),
          lastReviewedAt: lastReviewedAt,
          nextReviewDate: nextReviewDate,
          strengthLevel: strengthLevel,
          totalReviews: totalReviews,
        ),
      );

  bool get isDue => reviewClassification.isDue;
  bool get isNew => reviewClassification.isNew;
  bool get isMemorized => reviewClassification.isMemorized;
  bool get isMemorizedDue => reviewClassification.isMemorizedDue;
  bool get isVisibleForReview => reviewClassification.isVisibleForReview;

  /// Near revision: reviewed within last 5 days
  bool get isNearRevision => reviewClassification.isNearRevision;

  /// Far revision: reviewed more than 5 days ago
  bool get isFarRevision => reviewClassification.isFarRevision;

  String get key => '${surahId}_$ayahNumber';

  AyahReviewRecord copyWith({
    int? strengthLevel,
    int? intervalDays,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    int? totalReviews,
    PerformanceRating? lastRating,
    double? easeFactor,
    int? lapses,
    double? difficulty,
    double? stability,
    ReviewState? reviewState,
    ReviewRecordCreatedByMode? createdByMode,
    double? predictedRetrievability,
    int? predictedFsrsIntervalDays,
    DateTime? predictedFsrsDueDate,
    double? predictedRecallProbability,
    int? schedulerVsFsrsGapDays,
    double? schedulerVsFsrsRatio,
    bool? schedulerEarlierThanFsrs,
  }) => AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel ?? this.strengthLevel,
    intervalDays: intervalDays ?? this.intervalDays,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    totalReviews: totalReviews ?? this.totalReviews,
    lastRating: lastRating ?? this.lastRating,
    easeFactor: easeFactor ?? this.easeFactor,
    lapses: lapses ?? this.lapses,
    difficulty: difficulty ?? this.difficulty,
    stability: stability ?? this.stability,
    reviewState: reviewState ?? this.reviewState,
    createdByMode: createdByMode ?? this.createdByMode,
    predictedRetrievability: predictedRetrievability ?? this.predictedRetrievability,
    predictedFsrsIntervalDays: predictedFsrsIntervalDays ?? this.predictedFsrsIntervalDays,
    predictedFsrsDueDate: predictedFsrsDueDate ?? this.predictedFsrsDueDate,
    predictedRecallProbability: predictedRecallProbability ?? this.predictedRecallProbability,
    schedulerVsFsrsGapDays: schedulerVsFsrsGapDays ?? this.schedulerVsFsrsGapDays,
    schedulerVsFsrsRatio: schedulerVsFsrsRatio ?? this.schedulerVsFsrsRatio,
    schedulerEarlierThanFsrs: schedulerEarlierThanFsrs ?? this.schedulerEarlierThanFsrs,
  );

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    strengthLevel,
    intervalDays,
    nextReviewDate,
    totalReviews,
    lastRating,
    easeFactor,
    lapses,
    difficulty,
    stability,
    reviewState,
    createdByMode,
    predictedRetrievability,
    predictedFsrsIntervalDays,
    predictedFsrsDueDate,
    predictedRecallProbability,
    schedulerVsFsrsGapDays,
    schedulerVsFsrsRatio,
    schedulerEarlierThanFsrs,
  ];
}
