import '../../features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_receipt.dart';
import '../../features/prayer_review/data/repositories/isar_prayer_review_repository.dart';
import '../../features/prayer_review/domain/entities/prayer_review_selection.dart';
import 'backup_sections.dart';

/// Owner-derived hashes are recomputed after rebinding; device IDs never travel.
abstract final class PrayerReviewBackupMapper {
  static Map<String, Object?> assignmentToJson(IsarPrayerReviewAssignment row) {
    final value = IsarPrayerReviewRepository.selectionFromRow(row);
    return {
      ..._range(
        value.localDayKey,
        value.surahId,
        value.startAyah,
        value.endAyah,
      ),
      'prayerKeyIndex': value.prayerKey.index,
      'scheduledAt': value.scheduledAt.toIso8601String(),
      'selectedAt': value.selectedAt.toIso8601String(),
      'selectionVersion': value.selectionVersion,
      'promptConsumed': value.promptConsumed,
    };
  }

  static Map<String, Object?> receiptToJson(IsarPrayerReviewReceipt row) {
    final value = IsarPrayerReviewRepository.receiptFromRow(row);
    return {
      ..._range(
        value.localDayKey,
        value.surahId,
        value.startAyah,
        value.endAyah,
      ),
      'gradeIndex': value.gradeIndex,
      'committedAt': value.committedAt.toIso8601String(),
      'eventIds': value.eventIds,
    };
  }

  static IsarPrayerReviewAssignment assignmentFromJson(
    Object? raw,
    String owner,
  ) {
    final map = _map(raw, {
      ..._rangeFields,
      'prayerKeyIndex',
      'scheduledAt',
      'selectedAt',
      'selectionVersion',
      'promptConsumed',
    });
    try {
      final consumed = map['promptConsumed'];
      if (consumed is! bool) throw const FormatException();
      return IsarPrayerReviewRepository.assignmentFrom(
        PrayerReviewSelection(
          ownerId: owner,
          localDayKey: _string(map, 'localDayKey'),
          prayerKey: PrayerReviewValidation.prayerKeyFromIndex(
            _int(map, 'prayerKeyIndex'),
          ),
          scheduledAt: _date(map, 'scheduledAt'),
          selectedAt: _date(map, 'selectedAt'),
          surahId: _int(map, 'surahId'),
          startAyah: _int(map, 'startAyah'),
          endAyah: _int(map, 'endAyah'),
          selectionVersion: _int(map, 'selectionVersion'),
          promptConsumed: consumed,
        ),
      );
    } on FormatException {
      throw const BackupSectionInvalid('prayerReviewAssignment value');
    }
  }

  static IsarPrayerReviewReceipt receiptFromJson(Object? raw, String owner) {
    final map = _map(raw, {
      ..._rangeFields,
      'gradeIndex',
      'committedAt',
      'eventIds',
    });
    try {
      final ids = map['eventIds'];
      if (ids is! List || ids.any((id) => id is! String)) {
        throw const FormatException();
      }
      return PrayerReviewReceiptTransactionWriter.rowFromReceipt(
        PrayerReviewReceipt(
          ownerId: owner,
          localDayKey: _string(map, 'localDayKey'),
          surahId: _int(map, 'surahId'),
          startAyah: _int(map, 'startAyah'),
          endAyah: _int(map, 'endAyah'),
          gradeIndex: _int(map, 'gradeIndex'),
          committedAt: _date(map, 'committedAt'),
          eventIds: ids.cast<String>(),
        ),
      );
    } on FormatException {
      throw const BackupSectionInvalid('prayerReviewReceipt value');
    }
  }

  static const _rangeFields = {
    'ownerId',
    'audience',
    'localDayKey',
    'surahId',
    'startAyah',
    'endAyah',
  };

  static Map<String, Object?> _range(
    String day,
    int surah,
    int start,
    int end,
  ) => {
    'ownerId': kBackupOwnerToken,
    'audience': 'adult',
    'localDayKey': day,
    'surahId': surah,
    'startAyah': start,
    'endAyah': end,
  };

  static Map<String, Object?> _map(Object? raw, Set<String> fields) {
    if (raw is! Map<String, Object?> ||
        raw.length != fields.length ||
        !fields.every(raw.containsKey) ||
        raw['ownerId'] != kBackupOwnerToken ||
        raw['audience'] != 'adult') {
      throw const BackupSectionInvalid('prayerReview fields');
    }
    return raw;
  }

  static String _string(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String) throw const FormatException();
    return value;
  }

  static int _int(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! int) throw const FormatException();
    return value;
  }

  static DateTime _date(Map<String, Object?> map, String key) {
    final date = DateTime.tryParse(_string(map, key));
    if (date == null || !date.isUtc) throw const FormatException();
    return date;
  }
}
