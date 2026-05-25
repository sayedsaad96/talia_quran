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
      ..lastRatingIndex = model.lastRating?.index;
  }
}
