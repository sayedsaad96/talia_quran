import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import 'review_record_filters.dart';

/// Which audience bucket to use when reading/writing review rows.
enum ReviewRecordReadScope {
  /// Adult V2 / Hifz production records (`v2Session`, `hifz`, legacy adult).
  adult,

  /// Kids Mode records (`kidsMode` only).
  kids,
}

/// Audience helpers for review-record identity scoping.
///
/// Identity keys are always scoped (`owner|audience|surah|ayah`). The legacy
/// `adult_` / `kids_` prefixes remain only so migration can recognize Gen-2
/// composite keys written before owner identity landed.
class ReviewRecordAudienceScope {
  ReviewRecordAudienceScope._();

  static const adultPrefix = 'adult_';
  static const kidsPrefix = 'kids_';

  static String legacyKey(int surahId, int ayahNumber) =>
      '${surahId}_$ayahNumber';

  static bool isLegacyCompositeKey(String compositeKey) =>
      !compositeKey.startsWith(adultPrefix) &&
      !compositeKey.startsWith(kidsPrefix) &&
      !compositeKey.contains('|');

  static bool isAudiencePrefixedCompositeKey(String compositeKey) =>
      compositeKey.startsWith(adultPrefix) ||
      compositeKey.startsWith(kidsPrefix);

  static ReviewRecordReadScope scopeForWriteMode(
    ReviewRecordCreatedByMode mode,
  ) {
    return mode == ReviewRecordCreatedByMode.kidsMode
        ? ReviewRecordReadScope.kids
        : ReviewRecordReadScope.adult;
  }

  static bool matchesReadScope(
    AyahReviewRecord record,
    ReviewRecordReadScope scope,
  ) {
    return switch (scope) {
      ReviewRecordReadScope.kids => ReviewRecordFilters.isKidsSource(record),
      ReviewRecordReadScope.adult => !ReviewRecordFilters.isKidsSource(record),
    };
  }
}
