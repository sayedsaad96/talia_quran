import 'review_record_audience_scope.dart';
import 'review_record_identity.dart';
import '../../features/memorization_plus/domain/entities/memorization_entities.dart';

/// Filters a cloud push acknowledgement to identities that were sent locally.
///
/// Rows absent from the RPC result were rejected by the version conflict and
/// must remain dirty for a later local merge or retry.
class ReviewRecordCloudPushAcknowledgement {
  const ReviewRecordCloudPushAcknowledgement._();

  static Set<String> storageKeys({
    required String ownerUserId,
    required Iterable<AyahReviewRecord> sentRecords,
    required Iterable<Map<String, dynamic>> acknowledgedRows,
  }) {
    final sentKeys = sentRecords
        .map(
          (record) => ReviewRecordIdentity(
            ownerUserId: ownerUserId,
            audience: ReviewRecordAudienceScope.scopeForWriteMode(
              record.createdByMode,
            ),
            surahId: record.surahId,
            ayahNumber: record.ayahNumber,
          ).storageKey,
        )
        .toSet();

    final acknowledgedKeys = <String>{};
    for (final row in acknowledgedRows) {
      final surahId = _asInt(row['surah_id']);
      final ayahNumber = _asInt(row['ayah_number']);
      final audience = ReviewRecordReadScope.values
          .where((scope) => scope.name == row['audience'])
          .firstOrNull;
      if (surahId == null || ayahNumber == null || audience == null) continue;

      final key = ReviewRecordIdentity(
        ownerUserId: ownerUserId,
        audience: audience,
        surahId: surahId,
        ayahNumber: ayahNumber,
      ).storageKey;
      if (sentKeys.contains(key)) acknowledgedKeys.add(key);
    }
    return acknowledgedKeys;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
