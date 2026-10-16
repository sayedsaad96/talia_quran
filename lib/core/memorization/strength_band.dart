import '../../features/memorization_plus/domain/entities/ayah_review_record.dart';

/// Visual memorization-strength band of one ayah (display layer only).
enum StrengthBand { none, due, weak, building, solid }

/// Maps an adult review record to a [StrengthBand].
///
/// null or no reviews -> none; due (per the record's own classifier) -> due;
/// level <= 2 -> weak; 3-5 -> building; >= 6 -> solid.
StrengthBand strengthBandFor(AyahReviewRecord? record, DateTime now) {
  if (record == null || record.totalReviews <= 0) return StrengthBand.none;
  if (record.classifyAt(now).isDue) return StrengthBand.due;
  final level = record.strengthLevel;
  if (level >= 6) return StrengthBand.solid;
  if (level >= 3) return StrengthBand.building;
  return StrengthBand.weak;
}
