import 'dart:convert';
import 'prayer_review_backup_mapper.dart';
import '../prayer_review/prayer_review_lengths.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_receipt.dart';

import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/certificate/domain/entities/certificate_award.dart';
import '../../features/hifz/domain/entities/hifz_entities.dart';
import '../../features/khatmah/data/models/khatmah_history_model.dart';
import '../../features/khatmah/data/models/khatmah_plan_model.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/memorization_plus/data/models/memorization_models.dart';
import '../../features/memorization_plus/domain/entities/ayah_review_record.dart';
import '../../features/memorization_plus/domain/entities/kids_home_mission.dart';
import '../../features/memorization_plus/domain/entities/memorization_profile.dart';
import '../../features/settings/data/user_profile.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../../features/quran/data/models/isar_ayah_note.dart';
import '../../features/quran/domain/services/ayah_note_policy.dart';
import '../../features/memorization_plus/data/models/isar_confusion_pair.dart';
import '../../features/memorization_plus/data/repositories/isar_confusion_pair_repository.dart';
import '../constants/surah_names.dart';
import '../memorization/review_record_audience_scope.dart';
import '../memorization/review_record_identity.dart';
import '../utils/talia_logger.dart';

/// Section names of a versioned backup.
abstract final class BackupSections {
  static const reviewRecords = 'reviewRecords';
  static const ayahProgress = 'ayahProgress';
  static const streak = 'streak';
  static const xp = 'xp';
  static const dailyActivity = 'dailyActivity';
  static const prefs = 'prefs';
  static const ayahNotes = 'ayahNotes';
  static const confusionPairs = 'confusionPairs';
  static const prayerReviewAssignments = 'prayerReviewAssignments';
  static const prayerReviewReceipts = 'prayerReviewReceipts';

  static const v1 = {
    reviewRecords,
    ayahProgress,
    streak,
    xp,
    dailyActivity,
    prefs,
  };
  static const v2 = {...v1, ayahNotes};
  static const v3 = {...v2, confusionPairs};
  static const v4 = {...v3, prayerReviewAssignments, prayerReviewReceipts};
  static const all = v4;
  static Set<String> forVersion(int version) => switch (version) {
    1 => v1,
    2 => v2,
    3 => v3,
    4 => v4,
    _ => throw const BackupSectionInvalid('schemaVersion'),
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
  /// Bookmarks are deliberately absent: in production they live in encrypted
  /// account storage, which v1 backups do not carry.
  static const fixedKeys = {
    'user_profile',
    'read_pages',
    'khatmah_active_plan',
    'khatmah_history',
    'earned_certificates_v2',
    'earned_certificates_v2_kids',
    PrayerReviewLengths.baseKey,
  };

  static const prefixes = {
    'mem_plus_',
    'hifz_',
    'daily_read_pages_',
    'daily_wird_target_',
    'azkar_counter_',
    // The day stamps that make the counters above mean "today".
    'azkar_date_',
    'azkar_all_done_',
    'azkar_smart_wird_',
    'ramadan_',
    'hijri_year_recap_dismissed_',
    // Per-owner feature and season on/off choices (feature/season settings).
    'feature_pref_',
    'season_pref_',
    // Per-owner season marks: fasted days, read Fridays, hidden cards, badges.
    'season_flag_',
  };

  /// Prefixes whose remainder is the owner id itself (no `|` separator),
  /// optionally followed by a suffix matching the pattern.
  /// `adult_journey_v1_` stores `Uri.encodeComponent(ownerId)`.
  static final Map<String, RegExp?> ownerSuffixPrefixes = {
    'kids_reading_receipts_': null,
    'kids_support_profile_': null,
    'kids_family_practice_': null,
    'kids_streak_': null,
    'kids_achievements_': null,
    'kids_map_seen_completed_': RegExp(r'^_\d+$'),
    'kids_quran_map_seen_completed_': null,
    'adult_journey_v1_': null,
  };

  /// Kids bases stored as `base|<owner>`. Their unscoped (pre-owner legacy)
  /// form is never exported.
  static const ownerScopedKidsBases = {
    PrayerReviewLengths.baseKey,
    'mem_plus_kids_progress',
    'mem_plus_kids_legacy_cloud_floor',
    'mem_plus_kids_session_logs',
    'mem_plus_parent_settings',
    'mem_plus_parent_rewards',
    'mem_plus_home_missions',
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

  /// Device-local keys inside an allowlisted prefix. They are never collected
  /// and never removed or written by a restore; a file that still carries
  /// one has it skipped, not rejected.
  static const deviceLocalKeys = {'mem_plus_is_parent_mode'};

  static const _parentSettingsBase = 'mem_plus_parent_settings';
  static const _profileBase = 'mem_plus_profile';

  /// Fields of the parent settings that belong to this device (PIN marker,
  /// link and link-sync state). A restore keeps the device's values.
  static const parentSettingsDeviceFields = [
    'pinHash',
    'remoteLinkEnabled',
    'policySyncedVersion',
    'policyLinkConfirmed',
  ];

  /// Fields of the memorization profile that belong to this device (guardian
  /// role, link and link onboarding). A restore keeps the device's values.
  static const profileDeviceFields = [
    'guardianId',
    'linkedChildId',
    'guardianLinkStatus',
    'guardianOnboardingStatus',
    'isParentGuardian',
  ];

  static String _ownerForm(String prefix, String ownerId) =>
      prefix == 'adult_journey_v1_' ? Uri.encodeComponent(ownerId) : ownerId;

  static String? _familyOf(String key) =>
      ownerSuffixPrefixes.keys.where(key.startsWith).firstOrNull;

  /// The key as stored in a backup, or null when [key] is not backed up for
  /// [ownerId] (not allowlisted, excluded, corrupt, or another owner's).
  static String? backupKeyFor(String key, String ownerId) {
    if (key.contains(kBackupOwnerToken)) return null;
    if (deviceLocalKeys.contains(key)) return null;
    final String tokenized;
    if (key.contains('|')) {
      final parts = key.split('|');
      // `base|owner|corrupt` and every other shape are excluded.
      if (parts.length != 2 || parts[1] != ownerId) return null;
      final base = parts[0];
      if (_familyOf(base) != null) return null;
      if (!_allowlisted(base)) return null;
      tokenized = '$base|$kBackupOwnerToken';
    } else {
      final family = _familyOf(key);
      if (family != null) {
        final rest = key.substring(family.length);
        final form = _ownerForm(family, ownerId);
        if (!rest.startsWith(form)) return null;
        final suffix = rest.substring(form.length);
        final pattern = ownerSuffixPrefixes[family];
        if (suffix.isNotEmpty &&
            (pattern == null || !pattern.hasMatch(suffix))) {
          return null;
        }
        tokenized = '$family$kBackupOwnerToken$suffix';
      } else if (_allowlisted(key) && !ownerScopedKidsBases.contains(key)) {
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
      final family = _familyOf(backupKey);
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

  /// Strips account-link and PIN state from values that carry it, so a
  /// backup never moves a PIN hash, a guardian/child link or link-sync state
  /// to another account or device. Returns null when such a value cannot be
  /// read (it is then dropped on collect and rejected on restore). Every
  /// other value is returned unchanged.
  static Object? sanitize(String backupKey, Object value) {
    final base = backupKey.split('|').first;
    if (base != _parentSettingsBase && base != _profileBase) return value;
    if (value is! String) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final json = Map<String, dynamic>.of(decoded);
    if (base == _parentSettingsBase) {
      json.remove('pinHash');
      json['remoteLinkEnabled'] = false;
      json['policySyncedVersion'] = 0;
      json.remove('policyLinkConfirmed');
    } else {
      var unlinked = false;
      for (final field in const ['guardianId', 'linkedChildId']) {
        if (json.remove(field) != null) unlinked = true;
      }
      final status = json['guardianLinkStatus'];
      if (status == GuardianLinkStatus.linked.name ||
          status == GuardianLinkStatus.pending.name ||
          status == GuardianLinkStatus.linked.index ||
          status == GuardianLinkStatus.pending.index) {
        json['guardianLinkStatus'] = GuardianLinkStatus.none.name;
        unlinked = true;
      }
      // An unlinked child must go through guardian onboarding again, or the
      // routes that offer linking are skipped.
      final path = json['selectedPath'];
      if (unlinked &&
          (path == MemorizationPath.child.name ||
              path == MemorizationPath.child.index)) {
        json['guardianOnboardingStatus'] =
            GuardianOnboardingStatus.required.name;
      }
    }
    return jsonEncode(json);
  }

  /// Whether [key] (a real key) holds device-local PIN or link fields that a
  /// restore must keep: the restored value is merged with the device's
  /// ([mergeDeviceState]), and a backup without the key leaves the device's
  /// value in place.
  static bool keepsDeviceState(String key) {
    final base = key.split('|').first;
    return base == _parentSettingsBase || base == _profileBase;
  }

  /// The [restored] (sanitized) value of [key] with this device's PIN and
  /// link fields from [device] put back; a field the device lacks is
  /// dropped. Without a readable device value the restored parent settings
  /// are returned as they are, and the restored profile loses the guardian
  /// role (it belongs to the device that held it).
  static String mergeDeviceState(String key, String restored, String? device) {
    final Map<String, dynamic> target;
    try {
      final r = jsonDecode(restored);
      if (r is! Map<String, dynamic>) return restored;
      target = Map<String, dynamic>.of(r);
    } on FormatException {
      return restored;
    }
    final isProfile = key.split('|').first == _profileBase;
    Map<String, dynamic>? source;
    if (device != null) {
      try {
        final d = jsonDecode(device);
        if (d is Map<String, dynamic>) source = d;
      } on FormatException {
        source = null;
      }
    }
    if (source == null) {
      if (!isProfile) return restored;
      target['isParentGuardian'] = false;
      return jsonEncode(target);
    }
    final fields = isProfile ? profileDeviceFields : parentSettingsDeviceFields;
    for (final field in fields) {
      if (source.containsKey(field)) {
        target[field] = source[field];
      } else {
        target.remove(field);
      }
    }
    return jsonEncode(target);
  }

  /// Checks a (sanitized) value against the type its store writes and, for
  /// JSON values with a model, decodes it through the model the app reads
  /// it with. Throws [BackupSectionInvalid]. Keys without a known spec (an
  /// allowlisted prefix the policy does not describe) pass unchecked.
  static void validate(String backupKey, Object value) {
    final spec = _specFor(backupKey);
    if (spec == null) return;
    try {
      spec(value);
    } on BackupSectionInvalid catch (e) {
      throw BackupSectionInvalid('prefs value $backupKey: ${e.message}');
    } catch (e) {
      // A model parser's TypeError/FormatException/ArgumentError.
      throw BackupSectionInvalid('prefs value $backupKey: $e');
    }
  }

  static void Function(Object value)? _specFor(String backupKey) {
    final base = backupKey.split('|').first;
    final exact = _exactSpecs[base];
    if (exact != null) return exact;
    final family = _familyOf(base);
    if (family != null) {
      if (family == 'kids_map_seen_completed_') return _intStringList;
      if (family == 'kids_quran_map_seen_completed_') return _intStringList;
      if (family == 'adult_journey_v1_') return _string();
      return _string(_anyJson);
    }
    for (final entry in _prefixSpecs.entries) {
      if (base.startsWith(entry.key)) return entry.value;
    }
    return null;
  }

  static final Map<String, void Function(Object value)> _exactSpecs = {
    PrayerReviewLengths.baseKey: (value) {
      if (value is! String) throw const BackupSectionInvalid('prayer review lengths');
      PrayerReviewLengths.decode(value);
    },
    'user_profile': _string(_mapOf(UserProfile.fromJson)),
    'read_pages': _string(_pages),
    'khatmah_active_plan': _string(_mapOf(KhatmahPlanModel.fromJson)),
    for (final entry in _listItemModels.entries)
      entry.key: _string(_listOf(entry.value)),
    _profileBase: _string(_mapOf(MemorizationProfileModel.fromJson)),
    _parentSettingsBase: _string(_mapOf(ParentSettingsModel.fromJson)),
    'mem_plus_kids_progress': _string(_mapOf(KidsProgressModel.fromJson)),
    'mem_plus_kids_legacy_cloud_floor': _string(
      _mapOf(KidsProgressModel.fromJson),
    ),
    'mem_plus_daily_plan': _string(_mapOf(DailyPlanModel.fromJson)),
    'mem_plus_custom_plan': _string(
      _mapOf(CustomMemorizationPlanModel.fromJson),
    ),
    'mem_plus_smart_settings': _string(
      _mapOf(SmartMemorizationSettingsModel.fromJson),
    ),
    'mem_plus_track': _string(),
    'hifz_path_mode': _string(),
    'ramadan_tarawih': _string(_jsonList),
    'azkar_smart_wird_history': _string(_jsonList),
  };

  /// List values whose items are checked one by one by their model.
  static final Map<String, Object Function(Map<String, dynamic> json)>
  _listItemModels = {
    'khatmah_history': KhatmahHistoryModel.fromJson,
    'earned_certificates_v2': CertificateAward.fromJson,
    'earned_certificates_v2_kids': CertificateAward.fromJson,
    'mem_plus_parent_rewards': ParentRewardModel.fromJson,
    'mem_plus_kids_session_logs': KidsSessionLogModel.fromJson,
    'mem_plus_home_missions': KidsHomeMission.fromJson,
  };

  /// Drops the items of a model-checked JSON list that their model rejects
  /// and keeps the rest, so one corrupt item never costs the whole list (the
  /// app's readers salvage item by item too). Unchanged when nothing is
  /// dropped, when [backupKey] is not such a list, or when the value is not
  /// a JSON list at all ([validate] rejects that).
  static Object dropInvalidListItems(String backupKey, Object value) {
    final parse = _listItemModels[backupKey.split('|').first];
    if (parse == null || value is! String) return value;
    final Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      return value;
    }
    if (decoded is! List) return value;
    final kept = <Object?>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      try {
        parse(item);
        kept.add(item);
      } catch (_) {
        // Dropped below.
      }
    }
    if (kept.length == decoded.length) return value;
    TaliaLogger.w(
      'Backup dropped ${decoded.length - kept.length} invalid item(s) of '
      '$backupKey',
    );
    return jsonEncode(kept);
  }

  /// Checked in order; the first matching prefix wins.
  static final Map<String, void Function(Object value)> _prefixSpecs = {
    'daily_read_pages_': _string(_pages),
    'daily_wird_target_': _int,
    'azkar_counter_': _int,
    'azkar_date_': _string(),
    'azkar_all_done_': _bool,
    'azkar_smart_wird_active': _string(_jsonMap),
    'azkar_smart_wird_xp': _string(),
    'ramadan_card_dismissed_': _bool,
    'hijri_year_recap_dismissed_': _bool,
    'feature_pref_': _bool,
    'season_pref_': _bool,
    'season_flag_': _bool,
  };

  static void Function(Object value) _string([
    void Function(Object? decoded)? check,
  ]) => (value) {
    if (value is! String) throw const BackupSectionInvalid('not a string');
    if (check == null) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      throw const BackupSectionInvalid('not JSON');
    }
    check(decoded);
  };

  static void _int(Object value) {
    if (value is! int) throw const BackupSectionInvalid('not an int');
  }

  static void _bool(Object value) {
    if (value is! bool) throw const BackupSectionInvalid('not a bool');
  }

  static void _intStringList(Object value) {
    if (value is! List ||
        value.any((e) => e is! String || int.tryParse(e) == null)) {
      throw const BackupSectionInvalid('not a list of numbers');
    }
  }

  static void _anyJson(Object? decoded) {}

  static void _jsonList(Object? decoded) {
    if (decoded is! List) throw const BackupSectionInvalid('not a list');
  }

  static void _jsonMap(Object? decoded) {
    if (decoded is! Map) throw const BackupSectionInvalid('not an object');
  }

  static void _pages(Object? decoded) {
    if (decoded is! List || decoded.any((p) => p is! int || p < 1 || p > 604)) {
      throw const BackupSectionInvalid('not a list of pages');
    }
  }

  static void Function(Object? decoded) _mapOf(
    Object Function(Map<String, dynamic> json) fromJson,
  ) => (decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw const BackupSectionInvalid('not an object');
    }
    fromJson(decoded);
  };

  static void Function(Object? decoded) _listOf(
    Object Function(Map<String, dynamic> json) fromJson,
  ) => (decoded) {
    if (decoded is! List) throw const BackupSectionInvalid('not a list');
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        throw const BackupSectionInvalid('list item is not an object');
      }
      fromJson(item);
    }
  };

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
    } else {
      final parsed = ReviewRecordIdentity.tryParse(row.compositeKey);
      if (parsed != null) {
        return parsed.ownerUserId == ownerId ? parsed.audience : null;
      }
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
    final date = DateTime.utc(y, mo, d);
    if (y < 1900 || y > 9999 || date.month != mo || date.day != d) {
      throw BackupSectionInvalid('dayKey $dayKey');
    }
    return DailyActivityIsar()
      ..dayKey = dayKey
      ..activityCount = _int(m, 'activityCount', min: 0)
      ..cloudDirty = true
      ..lastSyncedAt = null;
  }
}

abstract final class AyahNoteBackupMapper {
  static Map<String, Object?> toJson(IsarAyahNote note) => {
    'ownerId': kBackupOwnerToken,
    'surahId': note.surahId,
    'ayahNumber': note.ayahNumber,
    'body': note.body,
    'createdAt': _iso(note.createdAt),
    'updatedAt': _iso(note.updatedAt),
  };

  static IsarAyahNote fromJson(Object? raw, String ownerId, {DateTime? now}) {
    final m = _map(raw, 'ayahNote');
    const fields = {
      'ownerId',
      'surahId',
      'ayahNumber',
      'body',
      'createdAt',
      'updatedAt',
    };
    if (m.length != fields.length || !fields.every(m.containsKey)) {
      throw const BackupSectionInvalid('ayahNote fields');
    }
    if (m['ownerId'] != kBackupOwnerToken) {
      throw const BackupSectionInvalid('ayahNote owner');
    }
    final body = m['body'];
    if (body is! String) throw const BackupSectionInvalid('ayahNote body');
    final surahId = _int(m, 'surahId');
    final ayahNumber = _int(m, 'ayahNumber');
    final createdAt = _date(m, 'createdAt');
    final updatedAt = _date(m, 'updatedAt');
    try {
      AyahNotePolicy.checkReference(surahId, ayahNumber);
      AyahNotePolicy.checkBody(body);
      AyahNotePolicy.checkDates(createdAt, updatedAt);
    } on FormatException {
      throw const BackupSectionInvalid('ayahNote invalid');
    }
    // A timestamp in the future (clock skew, tampering) would pin the note:
    // upsert never lowers updatedAt. Clamp to now; order is preserved because
    // createdAt <= updatedAt was verified above.
    final limit = (now ?? DateTime.now()).toUtc();
    DateTime clamp(DateTime value) =>
        value.toUtc().isAfter(limit) ? limit : value;
    return IsarAyahNote()
      ..ownerId = ownerId
      ..surahId = surahId
      ..ayahNumber = ayahNumber
      ..body = body
      ..createdAt = clamp(createdAt)
      ..updatedAt = clamp(updatedAt);
  }
}

abstract final class ConfusionPairBackupMapper {
  static Map<String, Object?> toJson(IsarConfusionPair pair) => {
    'ownerId': kBackupOwnerToken,
    'audience': pair.audience,
    'targetKey': pair.targetKey,
    'otherKey': pair.otherKey,
    'count': pair.count,
    'firstAt': _iso(pair.firstAt),
    'lastAt': _iso(pair.lastAt),
  };

  static IsarConfusionPair fromJson(Object? raw, String ownerId) {
    final map = _map(raw, 'confusionPair');
    const fields = {
      'ownerId', 'audience', 'targetKey', 'otherKey', 'count', 'firstAt', 'lastAt',
    };
    if (map.length != fields.length || !fields.every(map.containsKey)) {
      throw const BackupSectionInvalid('confusionPair fields');
    }
    if (map['ownerId'] != kBackupOwnerToken ||
        map['audience'] != IsarConfusionPair.adultAudience) {
      throw const BackupSectionInvalid('confusionPair owner or audience');
    }
    final target = _key(map['targetKey']);
    final other = _key(map['otherKey']);
    if (target == other) throw const BackupSectionInvalid('confusionPair self');
    final count = _int(map, 'count', min: 1);
    if (count > ConfusionPairTransactionWriter.maxCount) {
      throw const BackupSectionInvalid('confusionPair count');
    }
    final firstAt = _date(map, 'firstAt');
    final lastAt = _date(map, 'lastAt');
    if (lastAt.isBefore(firstAt)) {
      throw const BackupSectionInvalid('confusionPair timestamps');
    }
    return IsarConfusionPair()
      ..ownerId = ownerId
      ..audience = IsarConfusionPair.adultAudience
      ..targetKey = map['targetKey'] as String
      ..otherKey = map['otherKey'] as String
      ..count = count
      ..firstAt = firstAt
      ..lastAt = lastAt;
  }

  static String _key(Object? value) {
    if (value is! String) throw const BackupSectionInvalid('confusionPair key');
    try {
      final parts = value.split(':');
      if (parts.length != 2) throw const FormatException();
      final surah = int.parse(parts[0]);
      final ayah = int.parse(parts[1]);
      ConfusionPairTransactionWriter.checkAyah(surah, ayah);
      if (value != '$surah:$ayah') throw const FormatException();
      return value;
    } on FormatException {
      throw const BackupSectionInvalid('confusionPair key');
    }
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
    required this.ayahNotes,
    required this.confusionPairs,
    required this.prayerAssignments,
    required this.prayerReceipts,
    required this.prefs,
  });

  final List<IsarAyahReviewRecord> reviewRecords;
  final List<IsarAyahProgress> ayahProgress;
  final StreakIsar? streak;
  final XpIsar? xp;
  final List<DailyActivityIsar> dailyActivity;
  final List<IsarAyahNote> ayahNotes;
  final List<IsarConfusionPair> confusionPairs;
  final List<IsarPrayerReviewAssignment> prayerAssignments;
  final List<IsarPrayerReviewReceipt> prayerReceipts;

  /// Real (rebound) key → typed value.
  final Map<String, Object> prefs;

  /// Parses every section for [ownerId]; throws [BackupSectionInvalid].
  static ParsedBackupSections parse(
    Map<String, Object?> sections,
    String ownerId,
    int schemaVersion,
  ) {
    final expected = BackupSections.forVersion(schemaVersion);
    if (sections.length != expected.length ||
        !expected.every(sections.containsKey)) {
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

    final notes = schemaVersion == 1
        ? <IsarAyahNote>[]
        : [
            for (final note in _list(
              sections[BackupSections.ayahNotes],
              'ayahNotes',
            ))
              AyahNoteBackupMapper.fromJson(note, ownerId),
          ];
    _unique(notes.map((n) => '${n.surahId}:${n.ayahNumber}'), 'ayahNotes');

    final pairs = schemaVersion < 3
        ? <IsarConfusionPair>[]
        : [
            for (final pair in _list(
              sections[BackupSections.confusionPairs],
              'confusionPairs',
            ))
              ConfusionPairBackupMapper.fromJson(pair, ownerId),
          ];
    _unique(
      pairs.map((pair) => '${pair.targetKey}|${pair.otherKey}'),
      'confusionPairs',
    );

    final assignments = schemaVersion < 4 ? <IsarPrayerReviewAssignment>[] : [
      for (final row in _list(sections[BackupSections.prayerReviewAssignments], 'prayer assignments'))
        PrayerReviewBackupMapper.assignmentFromJson(row, ownerId),
    ];
    final receipts = schemaVersion < 4 ? <IsarPrayerReviewReceipt>[] : [
      for (final row in _list(sections[BackupSections.prayerReviewReceipts], 'prayer receipts'))
        PrayerReviewBackupMapper.receiptFromJson(row, ownerId),
    ];
    _unique(assignments.map((r) => r.occurrenceKey), 'prayer assignments');
    _unique(receipts.map((r) => r.receiptKey), 'prayer receipts');

    final prefs = <String, Object>{};
    final rawPrefs = _map(sections[BackupSections.prefs], 'prefs');
    for (final entry in rawPrefs.entries) {
      if (BackupPreferencePolicy.deviceLocalKeys.contains(entry.key)) continue;
      final key = BackupPreferencePolicy.restoreKeyFor(entry.key, ownerId);
      if (key == null) {
        throw BackupSectionInvalid('prefs key ${entry.key}');
      }
      final value = BackupPreferencePolicy.sanitize(
        entry.key,
        BackupPreferencePolicy.decodeValue(entry.value),
      );
      if (value == null) throw BackupSectionInvalid('prefs value ${entry.key}');
      final cleaned = BackupPreferencePolicy.dropInvalidListItems(
        entry.key,
        value,
      );
      BackupPreferencePolicy.validate(entry.key, cleaned);
      prefs[key] = cleaned;
    }

    return ParsedBackupSections._(
      reviewRecords: reviews,
      ayahProgress: progress,
      streak: StreakBackupMapper.fromJson(sections[BackupSections.streak]),
      xp: XpBackupMapper.fromJson(sections[BackupSections.xp]),
      dailyActivity: daily,
      ayahNotes: notes,
      confusionPairs: pairs,
      prayerAssignments: assignments,
      prayerReceipts: receipts,
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
