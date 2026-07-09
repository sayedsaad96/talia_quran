import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import 'review_record_filters.dart';

/// Which audience bucket to use when reading/writing Isar review rows (B4).
enum ReviewRecordReadScope {
  /// Adult V2 / Hifz production records (`v2Session`, `hifz`, legacy adult).
  adult,

  /// Kids Mode records (`kidsMode` only).
  kids,
}

/// Composite-key helpers and prefs flag for audience-scoped Isar storage.
///
/// When [isEnabled] is false, legacy `${surahId}_${ayahNumber}` keys are used
/// (backward compatible). When true, adult and kids rows are stored separately.
class ReviewRecordAudienceScope {
  ReviewRecordAudienceScope._();

  static const prefsKey = 'use_audience_scoped_reads';
  static const migrationKey = 'mem_plus_audience_scoped_keys_v1';

  static const adultPrefix = 'adult_';
  static const kidsPrefix = 'kids_';

  static bool isEnabled({required bool Function(String key) readBool}) =>
      readBool(prefsKey);

  static String legacyKey(int surahId, int ayahNumber) =>
      '${surahId}_$ayahNumber';

  static bool isLegacyCompositeKey(String compositeKey) =>
      !compositeKey.startsWith(adultPrefix) &&
      !compositeKey.startsWith(kidsPrefix);

  static String storageKey({
    required int surahId,
    required int ayahNumber,
    required ReviewRecordCreatedByMode mode,
    required bool scoped,
  }) {
    if (!scoped) return legacyKey(surahId, ayahNumber);
    final prefix = mode == ReviewRecordCreatedByMode.kidsMode
        ? kidsPrefix
        : adultPrefix;
    return '$prefix${surahId}_$ayahNumber';
  }

  static String readKey({
    required int surahId,
    required int ayahNumber,
    required ReviewRecordReadScope scope,
    required bool scoped,
  }) {
    if (!scoped) return legacyKey(surahId, ayahNumber);
    final prefix =
        scope == ReviewRecordReadScope.kids ? kidsPrefix : adultPrefix;
    return '$prefix${surahId}_$ayahNumber';
  }

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
