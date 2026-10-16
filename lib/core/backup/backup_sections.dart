import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/hifz/domain/entities/hifz_entities.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/memorization_plus/domain/entities/ayah_review_record.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../constants/surah_names.dart';
import '../memorization/review_record_audience_scope.dart';
import '../memorization/review_record_identity.dart';

/// Section names of a v1 backup. A v1 payload must carry exactly these.
abstract final class BackupSections {
  static const reviewRecords = 'reviewRecords';
  static const ayahProgress = 'ayahProgress';
  static const streak = 'streak';
  static const xp = 'xp';
  static const dailyActivity = 'dailyActivity';
  static const prefs = 'prefs';

  static const all = {
    reviewRecords,
    ayahProgress,
    streak,
    xp,
    dailyActivity,
    prefs,
  };
}

/// Placeholder written instead of the owner id in keys and owner fields.
const kBackupOwnerToken = '{owner}';

/// Thrown by the parsers below when a section is malformed or out of range.
class BackupSectionInvalid implements Exception {
  const BackupSectionInvalid(this.message);
  final String message;

  @override
  String toString() => 'BackupSectionInvalid: $message';
}

/// Which SharedPreferences keys a backup carries, and how owner ids inside
/// keys are replaced by [kBackupOwnerToken] and back.
abstract final class BackupPreferencePolicy {
  static const fixedKeys = {
    'user_profile',
    'read_pages',
    'quran_bookmarks',
    'khatmah_active_plan',
    'khatmah_history',
    'earned_certificates_v2',
    'earned_certificates_v2_kids',
  };

  static const prefixes = {
    'mem_plus_',
    'hifz_',
    'daily_read_pages_',
    'daily_wird_target_',
    'adult_journey_v1_',
    'azkar_counter_',
    'azkar_smart_wird_',
    'kids_reading_receipts_',
    'kids_support_profile_',
    'kids_family_practice_',
    'ramadan_',
    'quran_bookmarks_owner_',
  };

  /// Prefixes whose remainder is the owner id itself (no `|` separator).
  /// `adult_journey_v1_` stores `Uri.encodeComponent(ownerId)`.
  static const ownerSuffixPrefixes = {
    'quran_bookmarks_owner_',
    'kids_reading_receipts_',
    'kids_support_profile_',
    'kids_family_practice_',
    'adult_journey_v1_',
  };

  /// Substrings that exclude a key: sync bookkeeping, PINs, identity-claim
  /// markers (whose values are owner ids), quarantined corrupt payloads, and
  /// the short-lived guardian pairing code.
  static const excludedSubstrings = [
    'cloud',
    'cursor',
    'dirty',
    'revision',
    'conflict',
    'pin',
    'claimed_by',
    'quarantine',
    'mem_plus_pairing_session',
  ];

  static String _ownerForm(String prefix, String ownerId) =>
      prefix == 'adult_journey_v1_' ? Uri.encodeComponent(ownerId) : ownerId;

  /// The key as stored in a backup, or null when [key] is not backed up for
  /// [ownerId] (not allowlisted, excluded, corrupt, or another owner's).
  static String? backupKeyFor(String key, String ownerId) {
    if (key.contains(kBackupOwnerToken)) return null;
    final String tokenized;
    if (key.contains('|')) {
      final parts = key.split('|');
      // `base|owner|corrupt` and every other shape are excluded.
      if (parts.length != 2 || parts[1] != ownerId) return null;
      final base = parts[0];
      if (ownerSuffixPrefixes.any(base.startsWith)) return null;
      if (!_allowlisted(base)) return null;
      tokenized = '$base|$kBackupOwnerToken';
    } else {
      final family = ownerSuffixPrefixes.where(key.startsWith).firstOrNull;
      if (family != null) {
        final rest = key.substring(family.length);
        final form = _ownerForm(family, ownerId);
        if (rest == form) {
          tokenized = '$family$kBackupOwnerToken';
        } else if (family == 'quran_bookmarks_owner_' &&
            rest == '${form}_migrated') {
          tokenized = '$family${kBackupOwnerToken}_migrated';
        } else {
          return null;
        }
      } else if (_allowlisted(key)) {
        tokenized = key;
      } else {
        return null;
      }
    }
    if (excludedSubstrings.any(tokenized.contains)) return null;
    return tokenized;
  }

  /// The real key for a backup key under [ownerId], or null when the backup
  /// key is not one [backupKeyFor] could have produced.
  static String? restoreKeyFor(String backupKey, String ownerId) {
    final String key;
    if (!backupKey.contains(kBackupOwnerToken)) {
      key = backupKey;
    } else if (backupKey.contains('|')) {
      key = backupKey.replaceFirst(kBackupOwnerToken, ownerId);
    } else {
      final family = ownerSuffixPrefixes
          .where(backupKey.startsWith)
          .firstOrNull;
      if (family == null) return null;
      key = backupKey.replaceFirst(
        kBackupOwnerToken,
        _ownerForm(family, ownerId),
      );
    }
    return backupKeyFor(key, ownerId) == backupKey ? key : null;
  }

  static bool _allowlisted(String key) =>
      fixedKeys.contains(key) || prefixes.any(key.startsWith);

  /// `{"t": "s|i|d|b|l", "v": value}`; null for unsupported values.
  static Map<String, Object?>? encodeValue(Object? value) => switch (value) {
    final String v => {'t': 's', 'v': v},
    final int v => {'t': 'i', 'v': v},
    final double v when v.isFinite => {'t': 'd', 'v': v},
    final bool v => {'t': 'b', 'v': v},
    final List<String> v => {'t': 'l', 'v': List<String>.of(v)},
    final List<Object?> v when v.every((e) => e is String) => {
      't': 'l',
      'v': v.cast<String>().toList(),
    },
    _ => null,
  };

  /// Decoded typed value; throws [BackupSectionInvalid] on any mismatch.
  static Object decodeValue(Object? raw) {
    if (raw is! Map || raw.length != 2) {
      throw const BackupSectionInvalid('prefs value shape');
    }
    final t = raw['t'];
    final v = raw['v'];
    switch (t) {
      case 's' when v is String:
        return v;
      case 'i' when v is int:
        return v;
      case 'd' when v is num && v.isFinite:
        return v.toDouble();
      case 'b' when v is bool:
        return v;
      case 'l' when v is List && v.every((e) => e is String):
        return v.cast<String>().toList();
    }
    throw const BackupSectionInvalid('prefs value type');
  }
}

// ─── Shared field readers ──────────────────────────────────────────────────

Map<String, Object?> _map(Object? raw, String what) {
  if (raw is! Map) throw BackupSectionInvalid('$what is not an object');
  for (final k in raw.keys) {
    if (k is! String) throw BackupSectionInvalid('$what key');
  }
  return raw.cast<String, Object?>();
}

List<Object?> _list(Object? raw, String what) {
  if (raw is! List) throw BackupSectionInvalid('$what is not a list');
  return raw;
}

int _int(Map<String, Object?> m, String k, {int? min}) {
  final v = m[k];
  if (v is! int) throw BackupSectionInvalid('$k is not an int');
  if (min != null && v < min) throw BackupSectionInvalid('$k < $min');
  return v;
}

int? _intOrNull(Map<String, Object?> m, String k, {int? min}) =>
    m[k] == null ? null : _int(m, k, min: min);

double? _doubleOrNull(Map<String, Object?> m, String k) {
  final v = m[k];
  if (v == null) return null;
  if (v is! num || !v.isFinite) throw BackupSectionInvalid('$k not a number');
  return v.toDouble();
}

bool? _boolOrNull(Map<String, Object?> m, String k) {
  final v = m[k];
  if (v == null) return null;
  if (v is! bool) throw BackupSectionInvalid('$k not a bool');
  return v;
}

DateTime _date(Map<String, Object?> m, String k) {
  final v = m[k];
  final parsed = v is String ? DateTime.tryParse(v) : null;
  if (parsed == null) throw BackupSectionInvalid('$k not a date');
  return parsed.toUtc();
}

DateTime? _dateOrNull(Map<String, Object?> m, String k) =>
    m[k] == null ? null : _date(m, k);

String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

double? _finite(double? v) => v != null && v.isFinite ? v : null;

T? _enumByName<T extends Enum>(List<T> values, Object? name, String k) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw BackupSectionInvalid('$k unknown value $name');
}

T? _enumAt<T extends Enum>(List<T> values, int? index) =>
    index == null || index < 0 || index >= values.length ? null : values[index];

void _checkAyah(int surahId, int ayahNumber) {
  if (surahId < 1 || surahId > 114) {
    throw BackupSectionInvalid('surah $surahId out of range');
  }
  if (ayahNumber < 1 || ayahNumber > SurahNames.ayahCount(surahId)) {
    throw BackupSectionInvalid('ayah $surahId:$ayahNumber out of range');
  }
}

// ─── reviewRecords ─────────────────────────────────────────────────────────

/// Maps [IsarAyahReviewRecord] rows to and from backup JSON.
///
/// Sync bookkeeping (`cloudDirty`, `lastSyncedAt`) is not exported: a restored
/// row has never been uploaded under the restoring account, so it is written
/// dirty (or clean for the never-synced `local` owner), exactly like
/// guest-record claiming in `MemorizationReviewRecordsStorageMixin`.
abstract final class ReviewRecordBackupMapper {
  /// The audience this row belongs to, or null when the row is not the
  /// current owner's. Rows with a null owner (written before the identity
  /// migration) are treated as the current owner's, with the audience the
  /// migration would assign.
  static ReviewRecordReadScope? audienceFor(
    IsarAyahReviewRecord row,
    String ownerId,
  ) {
    final owner = row.ownerUserId;
    if (owner != null) {
      if (owner != ownerId) return null;
      final parsed = ReviewRecordIdentity.tryParse(row.compositeKey);
      if (parsed != null) {
        return parsed.ownerUserId == ownerId ? parsed.audience : null;
      }
      final named = row.audience == null
          ? null
          : ReviewRecordIdentity.audienceFromName(row.audience!);
      if (named != null) return named;
    }
    if (ReviewRecordAudienceScope.isAudiencePrefixedCompositeKey(
      row.compositeKey,
    )) {
      return row.compositeKey.startsWith(ReviewRecordAudienceScope.kidsPrefix)
          ? ReviewRecordReadScope.kids
          : ReviewRecordReadScope.adult;
    }
    return ReviewRecordAudienceScope.scopeForWriteMode(
      row.toModel().createdByMode,
    );
  }

  static Map<String, Object?> toJson(
    IsarAyahReviewRecord r,
    ReviewRecordReadScope audience,
  ) => {
    'ownerUserId': kBackupOwnerToken,
    'audience': audience.name,
    'surahId': r.surahId,
    'ayahNumber': r.ayahNumber,
    'strengthLevel': r.strengthLevel,
    'intervalDays': r.intervalDays,
    'lastReviewedAt': _iso(r.lastReviewedAt),
    'nextReviewDate': _iso(r.nextReviewDate),
    'totalReviews': r.totalReviews,
    'lastRating': _enumAt(PerformanceRating.values, r.lastRatingIndex)?.name,
    'easeFactor': _finite(r.easeFactor),
    'lapses': r.lapses,
    'createdByMode': _enumAt(
      ReviewRecordCreatedByMode.values,
      r.createdByModeIndex,
    )?.name,
    'difficulty': _finite(r.difficulty),
    'stability': _finite(r.stability),
    'reviewState': _enumAt(ReviewState.values, r.reviewStateIndex)?.name,
    'predictedRetrievability': _finite(r.predictedRetrievability),
    'predictedFsrsIntervalDays': r.predictedFsrsIntervalDays,
    'predictedFsrsDueDate': _iso(r.predictedFsrsDueDate),
    'predictedRecallProbability': _finite(r.predictedRecallProbability),
    'schedulerVsFsrsGapDays': r.schedulerVsFsrsGapDays,
    'schedulerVsFsrsRatio': _finite(r.schedulerVsFsrsRatio),
    'schedulerEarlierThanFsrs': r.schedulerEarlierThanFsrs,
  };

  static IsarAyahReviewRecord fromJson(Object? raw, String ownerId) {
    final m = _map(raw, 'reviewRecord');
    if (m['ownerUserId'] != kBackupOwnerToken) {
      throw const BackupSectionInvalid('reviewRecord owner');
    }
    final audienceName = m['audience'];
    final audience = audienceName is String
        ? ReviewRecordIdentity.audienceFromName(audienceName)
        : null;
    if (audience == null) {
      throw const BackupSectionInvalid('reviewRecord audience');
    }
    final surahId = _int(m, 'surahId');
    final ayahNumber = _int(m, 'ayahNumber');
    _checkAyah(surahId, ayahNumber);
    final identity = ReviewRecordIdentity(
      ownerUserId: ownerId,
      audience: audience,
      surahId: surahId,
      ayahNumber: ayahNumber,
    );
    return IsarAyahReviewRecord()
      ..compositeKey = identity.storageKey
      ..ownerUserId = ownerId
      ..audience = audience.name
      ..surahId = surahId
      ..ayahNumber = ayahNumber
      ..strengthLevel = _int(m, 'strengthLevel', min: 0)
      ..intervalDays = _int(m, 'intervalDays', min: 0)
      ..lastReviewedAt = _date(m, 'lastReviewedAt')
      ..nextReviewDate = _date(m, 'nextReviewDate')
      ..totalReviews = _int(m, 'totalReviews', min: 0)
      ..lastRatingIndex = _enumByName(
        PerformanceRating.values,
        m['lastRating'],
        'lastRating',
      )?.index
      ..easeFactor = _doubleOrNull(m, 'easeFactor')
      ..lapses = _intOrNull(m, 'lapses', min: 0)
      ..createdByModeIndex = _enumByName(
        ReviewRecordCreatedByMode.values,
        m['createdByMode'],
        'createdByMode',
      )?.index
      ..difficulty = _doubleOrNull(m, 'difficulty')
      ..stability = _doubleOrNull(m, 'stability')
      ..reviewStateIndex = _enumByName(
        ReviewState.values,
        m['reviewState'],
        'reviewState',
      )?.index
      ..predictedRetrievability = _doubleOrNull(m, 'predictedRetrievability')
      ..predictedFsrsIntervalDays = _intOrNull(m, 'predictedFsrsIntervalDays')
      ..predictedFsrsDueDate = _dateOrNull(m, 'predictedFsrsDueDate')
      ..predictedRecallProbability = _doubleOrNull(
        m,
        'predictedRecallProbability',
      )
      ..schedulerVsFsrsGapDays = _intOrNull(m, 'schedulerVsFsrsGapDays')
      ..schedulerVsFsrsRatio = _doubleOrNull(m, 'schedulerVsFsrsRatio')
      ..schedulerEarlierThanFsrs = _boolOrNull(m, 'schedulerEarlierThanFsrs')
      ..cloudDirty = ownerId != ReviewRecordIdentity.localOwnerId
      ..lastSyncedAt = null;
  }
}

// ─── ayahProgress ──────────────────────────────────────────────────────────

abstract final class AyahProgressBackupMapper {
  static Map<String, Object?> toJson(IsarAyahProgress p) => {
    'surahId': p.surahId,
    'ayahNumber': p.ayahNumber,
    'status': p.status.name,
    'repetitions': p.repetitions,
    'nextReviewDate': _iso(p.nextReviewDate),
    'lastReviewDate': _iso(p.lastReviewDate),
  };

  static IsarAyahProgress fromJson(Object? raw) {
    final m = _map(raw, 'ayahProgress');
    final surahId = _int(m, 'surahId');
    final ayahNumber = _int(m, 'ayahNumber');
    _checkAyah(surahId, ayahNumber);
    final status = _enumByName(AyahStatus.values, m['status'], 'status');
    if (status == null) throw const BackupSectionInvalid('status missing');
    return IsarAyahProgress()
      ..compositeKey = '${surahId}_$ayahNumber'
      ..surahId = surahId
      ..ayahNumber = ayahNumber
      ..status = status
      ..repetitions = _int(m, 'repetitions', min: 0)
      ..nextReviewDate = _date(m, 'nextReviewDate')
      ..lastReviewDate = _date(m, 'lastReviewDate');
  }
}

// ─── streak / xp / dailyActivity ───────────────────────────────────────────

/// Single-row collections are restored with their fixed id (1) and marked
/// dirty: they have not been uploaded under the restoring account.
abstract final class StreakBackupMapper {
  static Map<String, Object?> toJson(StreakIsar s) => {
    'currentStreak': s.currentStreak,
    'longestStreak': s.longestStreak,
    'lastActivityDate': _iso(s.lastActivityDate),
    'freezesAvailable': s.freezesAvailable,
    'lastMercyDate': _iso(s.lastMercyDate),
  };

  static StreakIsar? fromJson(Object? raw) {
    if (raw == null) return null;
    final m = _map(raw, 'streak');
    return StreakIsar()
      ..id = 1
      ..currentStreak = _int(m, 'currentStreak', min: 0)
      ..longestStreak = _int(m, 'longestStreak', min: 0)
      ..lastActivityDate = _dateOrNull(m, 'lastActivityDate')
      ..freezesAvailable = _int(m, 'freezesAvailable', min: 0)
      ..lastMercyDate = _dateOrNull(m, 'lastMercyDate')
      ..cloudDirty = true
      ..lastSyncedAt = null;
  }
}

abstract final class XpBackupMapper {
  static Map<String, Object?> toJson(XpIsar x) => {'totalXp': x.totalXp};

  static XpIsar? fromJson(Object? raw) {
    if (raw == null) return null;
    final m = _map(raw, 'xp');
    return XpIsar()
      ..id = 1
      ..totalXp = _int(m, 'totalXp', min: 0)
      ..cloudDirty = true
      ..lastSyncedAt = null;
  }
}

abstract final class DailyActivityBackupMapper {
  static Map<String, Object?> toJson(DailyActivityIsar d) => {
    'dayKey': d.dayKey,
    'activityCount': d.activityCount,
  };

  static DailyActivityIsar fromJson(Object? raw) {
    final m = _map(raw, 'dailyActivity');
    final dayKey = _int(m, 'dayKey');
    final y = dayKey ~/ 10000, mo = dayKey ~/ 100 % 100, d = dayKey % 100;
    if (y < 1900 || y > 9999 || mo < 1 || mo > 12 || d < 1 || d > 31) {
      throw BackupSectionInvalid('dayKey $dayKey');
    }
    return DailyActivityIsar()
      ..dayKey = dayKey
      ..activityCount = _int(m, 'activityCount', min: 0)
      ..cloudDirty = true
      ..lastSyncedAt = null;
  }
}

/// Every section of a payload, parsed and validated, ready to write.
class ParsedBackupSections {
  ParsedBackupSections._({
    required this.reviewRecords,
    required this.ayahProgress,
    required this.streak,
    required this.xp,
    required this.dailyActivity,
    required this.prefs,
  });

  final List<IsarAyahReviewRecord> reviewRecords;
  final List<IsarAyahProgress> ayahProgress;
  final StreakIsar? streak;
  final XpIsar? xp;
  final List<DailyActivityIsar> dailyActivity;

  /// Real (rebound) key → typed value.
  final Map<String, Object> prefs;

  /// Parses every section for [ownerId]; throws [BackupSectionInvalid].
  static ParsedBackupSections parse(
    Map<String, Object?> sections,
    String ownerId,
  ) {
    if (sections.length != BackupSections.all.length ||
        !BackupSections.all.every(sections.containsKey)) {
      throw const BackupSectionInvalid('section set');
    }

    final reviews = [
      for (final r in _list(sections[BackupSections.reviewRecords], 'reviews'))
        ReviewRecordBackupMapper.fromJson(r, ownerId),
    ];
    _unique(reviews.map((r) => r.compositeKey), 'reviewRecords');

    final progress = [
      for (final p in _list(sections[BackupSections.ayahProgress], 'progress'))
        AyahProgressBackupMapper.fromJson(p),
    ];
    _unique(progress.map((p) => p.compositeKey), 'ayahProgress');

    final daily = [
      for (final d in _list(sections[BackupSections.dailyActivity], 'daily'))
        DailyActivityBackupMapper.fromJson(d),
    ];
    _unique(daily.map((d) => d.dayKey), 'dailyActivity');

    final prefs = <String, Object>{};
    final rawPrefs = _map(sections[BackupSections.prefs], 'prefs');
    for (final entry in rawPrefs.entries) {
      final key = BackupPreferencePolicy.restoreKeyFor(entry.key, ownerId);
      if (key == null) {
        throw BackupSectionInvalid('prefs key ${entry.key}');
      }
      prefs[key] = BackupPreferencePolicy.decodeValue(entry.value);
    }

    return ParsedBackupSections._(
      reviewRecords: reviews,
      ayahProgress: progress,
      streak: StreakBackupMapper.fromJson(sections[BackupSections.streak]),
      xp: XpBackupMapper.fromJson(sections[BackupSections.xp]),
      dailyActivity: daily,
      prefs: prefs,
    );
  }

  static void _unique(Iterable<Object> keys, String what) {
    final seen = <Object>{};
    for (final k in keys) {
      if (!seen.add(k)) throw BackupSectionInvalid('$what duplicate $k');
    }
  }
}
