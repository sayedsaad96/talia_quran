import 'package:isar/isar.dart';

import '../../domain/entities/memorization_entities.dart';
import 'memorization_models.dart';

part 'isar_ayah_review_record.g.dart';

@collection
class IsarAyahReviewRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String compositeKey;

  late int surahId;
  late int ayahNumber;
  late int strengthLevel;
  late int intervalDays;
  late DateTime lastReviewedAt;
  late DateTime nextReviewDate;
  late int totalReviews;

  int? lastRatingIndex;

  /// SM-2 derived multiplier for the next interval
  double? easeFactor;

  /// Number of times this ayah was rated as weak after being reviewed
  int? lapses;

  /// Source metadata added in Sprint 7B.
  ///
  /// Stores [ReviewRecordCreatedByMode.index].  Records written before this
  /// field was introduced have `null` here, which [toModel] maps to
  /// [ReviewRecordCreatedByMode.unknown].  No Isar migration is required —
  /// Isar treats a new nullable field on existing documents as `null`.
  int? createdByModeIndex;

  /// FSRS: Current difficulty level
  double? difficulty;

  /// FSRS: Memory stability (in days)
  double? stability;

  /// FSRS: Current state of the card
  int? reviewStateIndex;

  /// FSRS: Shadow predicted retrievability
  double? predictedRetrievability;

  /// FSRS: Shadow predicted interval
  int? predictedFsrsIntervalDays;

  /// FSRS: Shadow predicted next review date
  DateTime? predictedFsrsDueDate;

  /// FSRS: Future shadow probability of recall
  double? predictedRecallProbability;

  int? schedulerVsFsrsGapDays;
  double? schedulerVsFsrsRatio;
  bool? schedulerEarlierThanFsrs;

  AyahReviewRecordModel toModel() {
    return AyahReviewRecordModel(
      surahId: surahId,
      ayahNumber: ayahNumber,
      strengthLevel: strengthLevel,
      intervalDays: intervalDays,
      lastReviewedAt: lastReviewedAt,
      nextReviewDate: nextReviewDate,
      totalReviews: totalReviews,
      lastRating:
          lastRatingIndex == null ||
              lastRatingIndex! < 0 ||
              lastRatingIndex! >= PerformanceRating.values.length
          ? null
          : PerformanceRating.values[lastRatingIndex!],
      createdByMode:
          createdByModeIndex == null ||
              createdByModeIndex! < 0 ||
              createdByModeIndex! >= ReviewRecordCreatedByMode.values.length
          ? ReviewRecordCreatedByMode.unknown
          : ReviewRecordCreatedByMode.values[createdByModeIndex!],
      easeFactor: easeFactor ?? 2.5,
      lapses: lapses ?? 0,
      difficulty: difficulty ?? 5.0,
      stability: stability ?? 0.0,
      reviewState:
          reviewStateIndex == null ||
              reviewStateIndex! < 0 ||
              reviewStateIndex! >= ReviewState.values.length
          ? ReviewState.newCard
          : ReviewState.values[reviewStateIndex!],
      predictedRetrievability: predictedRetrievability,
      predictedFsrsIntervalDays: predictedFsrsIntervalDays,
      predictedFsrsDueDate: predictedFsrsDueDate,
      predictedRecallProbability: predictedRecallProbability,
      schedulerVsFsrsGapDays: schedulerVsFsrsGapDays,
      schedulerVsFsrsRatio: schedulerVsFsrsRatio,
      schedulerEarlierThanFsrs: schedulerEarlierThanFsrs,
    );
  }

  static IsarAyahReviewRecord fromModel(AyahReviewRecordModel model) {
    return IsarAyahReviewRecord()
      ..compositeKey = '${model.surahId}_${model.ayahNumber}'
      ..surahId = model.surahId
      ..ayahNumber = model.ayahNumber
      ..strengthLevel = model.strengthLevel
      ..intervalDays = model.intervalDays
      ..lastReviewedAt = model.lastReviewedAt
      ..nextReviewDate = model.nextReviewDate
      ..totalReviews = model.totalReviews
      ..lastRatingIndex = model.lastRating?.index
      ..easeFactor = model.easeFactor
      ..lapses = model.lapses
      ..difficulty = model.difficulty
      ..stability = model.stability
      ..reviewStateIndex = model.reviewState.index
      ..createdByModeIndex = model.createdByMode.index
      ..predictedRetrievability = model.predictedRetrievability
      ..predictedFsrsIntervalDays = model.predictedFsrsIntervalDays
      ..predictedFsrsDueDate = model.predictedFsrsDueDate
      ..predictedRecallProbability = model.predictedRecallProbability
      ..schedulerVsFsrsGapDays = model.schedulerVsFsrsGapDays
      ..schedulerVsFsrsRatio = model.schedulerVsFsrsRatio
      ..schedulerEarlierThanFsrs = model.schedulerEarlierThanFsrs;
  }
}
