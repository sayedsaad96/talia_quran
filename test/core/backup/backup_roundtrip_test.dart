import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/backup/backup_collector.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';
import 'package:talia_quran/core/backup/backup_restorer.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/security/parent_pin_secure_store.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_completion_store.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/prayer_companion/data/models/prayer_companion_record_isar.dart';
import 'package:talia_quran/features/streak/data/models/daily_activity_isar.dart';
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';
import 'package:talia_quran/features/xp/data/models/xp_isar.dart';
import 'package:talia_quran/features/quran/data/models/isar_ayah_note.dart';

import '../../helpers/isar_test_core.dart';

/// Owner whose id the test can change at any moment.
class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

/// Returns [first] on the first read and [later] on every read after it.
class _SwitchingOwner implements RecordOwnerProvider {
  _SwitchingOwner(this.first, this.later);
  final String first;
  final String later;
  int reads = 0;

  @override
  String get currentOwnerId => reads++ == 0 ? first : later;

  @override
  bool get isSignedIn => true;
}

/// In-memory prefs store that lets a test fail or observe single writes.
class _HookStore extends InMemorySharedPreferencesStore {
  _HookStore.withData(super.data) : super.withData();

  /// Return false to make the write fail.
  bool Function(String key)? onSet;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final hook = onSet;
    if (hook != null && !hook(key.substring('flutter.'.length))) return false;
    return super.setValue(valueType, key, value);
  }
}

class _MemoryPinStore implements ParentPinSecureStore {
  final verifiers = <String, String>{};

  @override
  Future<String?> readVerifier(String ownerId) async => verifiers[ownerId];
  @override
  Future<void> writeVerifier(String ownerId, String verifier) async =>
      verifiers[ownerId] = verifier;
  @override
  Future<void> clearVerifier(String ownerId) async => verifiers.remove(ownerId);
  @override
  Future<DateTime?> readBlockedUntil(String ownerId) async => null;
  @override
  Future<void> writeBlockedUntil(String ownerId, DateTime? until) async {}
  @override
  Future<int> readFailureCount(String ownerId) async => 0;
  @override
  Future<void> writeFailureCount(String ownerId, int count) async {}
}

IsarAyahReviewRecord _review({
  required String key,
  required String? owner,
  String? audience,
  required int surah,
  required int ayah,
  int strength = 3,
}) => IsarAyahReviewRecord()
  ..compositeKey = key
  ..ownerUserId = owner
  ..audience = audience
  ..surahId = surah
  ..ayahNumber = ayah
  ..strengthLevel = strength
  ..intervalDays = 7
  ..lastReviewedAt = DateTime.utc(2026, 9, 1, 10, 30)
  ..nextReviewDate = DateTime.utc(2026, 9, 8, 10, 30)
  ..totalReviews = 5
  ..lastRatingIndex = PerformanceRating.average.index
  ..easeFactor = 2.3
  ..lapses = 1
  ..createdByModeIndex = ReviewRecordCreatedByMode.adultMemPlus.index
  ..difficulty = 4.5
  ..stability = 12.25
  ..reviewStateIndex = ReviewState.review.index
  ..predictedRetrievability = 0.9
  ..predictedFsrsIntervalDays = 9
  ..predictedFsrsDueDate = DateTime.utc(2026, 9, 10)
  ..predictedRecallProbability = 0.85
  ..schedulerVsFsrsGapDays = -2
  ..schedulerVsFsrsRatio = 0.78
  ..schedulerEarlierThanFsrs = true
  ..cloudDirty = false
  ..lastSyncedAt = DateTime.utc(2026, 9, 2);

CloudSyncQueueItem _queue(String kind, String owner) => CloudSyncQueueItem()
  ..kind = kind
  ..ownerUserId = owner
  ..nextRetryAt = DateTime.utc(2026, 9, 1)
  ..createdAt = DateTime.utc(2026, 9, 1);

Map<String, Object?> _prefsMap(SharedPreferences prefs) => {
  for (final k in prefs.getKeys()) k: prefs.get(k),
};

void main() {
  late Directory dir;
  final opened = <Isar>[];

  setUpAll(initializeIsarCoreForTests);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('talia_backup_');
  });

  tearDown(() async {
    for (final isar in opened) {
      await isar.close(deleteFromDisk: true);
    }
    opened.clear();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<Isar> openIsar(String tag) async {
    final isar = await Isar.open(
      appIsarSchemas,
      directory: dir.path,
      name: 'backup_${tag}_${DateTime.now().microsecondsSinceEpoch}',
    );
    opened.add(isar);
    return isar;
  }

  Future<SharedPreferences> freshPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  Future<({SharedPreferences prefs, _HookStore store})> hookedPrefs(
    Map<String, Object> values,
  ) async {
    final store = _HookStore.withData({
      for (final e in values.entries) 'flutter.${e.key}': e.value,
    });
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    return (prefs: await SharedPreferences.getInstance(), store: store);
  }

  Future<void> seedOwnerA(Isar isar) async {
    await isar.writeTxn(() async {
      await isar.isarAyahReviewRecords.putAll([
        _review(
          key: 'user-a|adult|2|255',
          owner: 'user-a',
          audience: 'adult',
          surah: 2,
          ayah: 255,
        ),
        _review(
          key: 'user-a|kids|114|6',
          owner: 'user-a',
          audience: 'kids',
          surah: 114,
          ayah: 6,
        )..createdByModeIndex = ReviewRecordCreatedByMode.kidsMode.index,
        // Another account's row and a guest row: never exported for user-a.
        _review(
          key: 'user-b|adult|1|1',
          owner: 'user-b',
          audience: 'adult',
          surah: 1,
          ayah: 1,
        ),
        _review(
          key: 'local|adult|1|2',
          owner: 'local',
          audience: 'adult',
          surah: 1,
          ayah: 2,
        ),
        // Null owner but an identity key of another owner: skipped.
        _review(key: 'user-z|adult|1|3', owner: null, surah: 1, ayah: 3),
        // Pre-identity legacy row: exported as the current owner's.
        _review(key: '3_4', owner: null, surah: 3, ayah: 4, strength: 2)
          ..createdByModeIndex = null,
      ]);
      await isar.isarAyahProgress.put(
        IsarAyahProgress()
          ..compositeKey = '1_1'
          ..surahId = 1
          ..ayahNumber = 1
          ..status = AyahStatus.memorized
          ..repetitions = 4
          ..nextReviewDate = DateTime.utc(2026, 9, 20)
          ..lastReviewDate = DateTime.utc(2026, 9, 1),
      );
      await isar.streakIsars.put(
        StreakIsar()
          ..currentStreak = 12
          ..longestStreak = 40
          ..lastActivityDate = DateTime.utc(2026, 9, 1)
          ..freezesAvailable = 2
          ..lastMercyDate = DateTime.utc(2026, 8, 1)
          ..cloudDirty = false,
      );
      await isar.xpIsars.put(XpIsar()..totalXp = 1234);
      await isar.dailyActivityIsars.put(
        DailyActivityIsar()
          ..dayKey = 20260901
          ..activityCount = 17,
      );
    });
  }

  final parentSettingsA = jsonEncode({
    'pinHash': 'pin-hash-secret',
    'reminderHour': 7,
    'remoteLinkEnabled': true,
    'policyVersion': 4,
    'policySyncedVersion': 4,
    'policyLinkConfirmed': true,
    'localChildNickname': 'Zaid',
  });
  final profileA = jsonEncode({
    'schemaVersion': 1,
    'selectedPath': 'kids',
    'guardianLinkStatus': 'linked',
    'linkedChildId': 'child-id-secret',
    'guardianId': 'guardian-id-secret',
    'isParentGuardian': true,
    'childAge': 8,
  });

  const userProfileA = '{"name":"Ahmad","age":30}';
  const khatmahPlanA =
      '{"id":"p1","title":"Khatmah","targetPagesPerDay":20,"targetDays":30,'
      '"startDate":"2026-09-01T00:00:00.000Z",'
      '"expectedEndDate":"2026-09-30T00:00:00.000Z"}';
  const kidsProgressA =
      '{"totalPoints":30,"currentLevel":1,"currentStreak":2,'
      '"starsEarned":3,"ayahsCompleted":4}';
  const homeMissionsA =
      '[{"id":"m1","title":"Tidy","status":"assigned",'
      '"createdAt":"2026-09-01T00:00:00.000Z"}]';

  Map<String, Object> ownerAPrefs() => {
    'read_pages': '[1,2]',
    'user_profile': userProfileA,
    'khatmah_active_plan': khatmahPlanA,
    'mem_plus_kids_progress|user-a': kidsProgressA,
    'mem_plus_home_missions|user-a': homeMissionsA,
    'mem_plus_parent_settings|user-a': parentSettingsA,
    'mem_plus_profile': profileA,
    'ramadan_tarawih|user-a': '[{"night":1}]',
    'ramadan_card_dismissed_start_1448|user-a': true,
    'kids_reading_receipts_user-a': '{"2026-09-08":[12]}',
    'kids_streak_user-a': '{"current":3}',
    'kids_achievements_user-a': '{"first":"2026-09-01"}',
    'kids_map_seen_completed_user-a_67': <String>['1', '2'],
    'adult_journey_v1_user-a': '{"v":1}',
    'daily_wird_target_2026-09-08': 12,
    'hifz_pace': 1.5,
    'mem_plus_track_list': <String>['a', 'b'],
  };

  Future<BackupPayload> collectA(Isar isar, SharedPreferences prefs) =>
      BackupCollector(
        isar,
        prefs,
        const FixedRecordOwnerProvider('user-a'),
      ).collect(DateTime.utc(2026, 10, 17));

  test('collect → encode → decode → restore under ANOTHER owner reproduces '
      'records with the new owner', () async {
    final isarA = await openIsar('a');
    await seedOwnerA(isarA);
    final payload = await collectA(isarA, await freshPrefs(ownerAPrefs()));

    final bytes = encodeBackup(payload);
    final decoded = decodeBackup(bytes);
    expect(decoded.error, isNull);

    final isarB = await openIsar('b');
    final prefsB = await freshPrefs({});
    final events = ProgressEventsBus();
    final reasons = <ProgressChangedReason>[];
    final sub = events.changes.listen(reasons.add);
    final result = await BackupRestorer(
      isarB,
      prefsB,
      const FixedRecordOwnerProvider('user-b'),
      events: events,
    ).restore(decoded.payload!);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(result, BackupRestoreResult.restored);
    expect(reasons, [ProgressChangedReason.cloudPull]);

    final reviews = await isarB.isarAyahReviewRecords.where().findAll();
    expect(reviews.map((r) => r.compositeKey).toSet(), {
      'user-b|adult|2|255',
      'user-b|kids|114|6',
      'user-b|adult|3|4',
    });
    expect(reviews.every((r) => r.ownerUserId == 'user-b'), isTrue);
    expect(reviews.every((r) => r.cloudDirty == true), isTrue);
    expect(reviews.every((r) => r.lastSyncedAt == null), isTrue);
    final r = reviews.singleWhere((r) => r.surahId == 2);
    expect(r.audience, 'adult');
    expect(r.strengthLevel, 3);
    expect(r.intervalDays, 7);
    expect(r.totalReviews, 5);
    expect(r.lastReviewedAt.toUtc(), DateTime.utc(2026, 9, 1, 10, 30));
    expect(r.nextReviewDate.toUtc(), DateTime.utc(2026, 9, 8, 10, 30));
    expect(r.lastRatingIndex, PerformanceRating.average.index);
    expect(r.easeFactor, 2.3);
    expect(r.lapses, 1);
    expect(r.createdByModeIndex, ReviewRecordCreatedByMode.adultMemPlus.index);
    expect(r.difficulty, 4.5);
    expect(r.stability, 12.25);
    expect(r.reviewStateIndex, ReviewState.review.index);
    expect(r.predictedRetrievability, 0.9);
    expect(r.predictedFsrsIntervalDays, 9);
    expect(r.predictedFsrsDueDate!.toUtc(), DateTime.utc(2026, 9, 10));
    expect(r.predictedRecallProbability, 0.85);
    expect(r.schedulerVsFsrsGapDays, -2);
    expect(r.schedulerVsFsrsRatio, 0.78);
    expect(r.schedulerEarlierThanFsrs, isTrue);
    final kids = reviews.singleWhere((r) => r.surahId == 114);
    expect(kids.audience, 'kids');
    final legacy = reviews.singleWhere((r) => r.surahId == 3);
    expect(legacy.strengthLevel, 2);
    expect(legacy.createdByModeIndex, isNull);

    final progress = await isarB.isarAyahProgress.where().findAll();
    expect(progress, hasLength(1));
    expect(progress.single.compositeKey, '1_1');
    expect(progress.single.status, AyahStatus.memorized);
    expect(progress.single.repetitions, 4);
    expect(progress.single.nextReviewDate.toUtc(), DateTime.utc(2026, 9, 20));
    final streak = (await isarB.streakIsars.get(1))!;
    expect(streak.currentStreak, 12);
    expect(streak.longestStreak, 40);
    expect(streak.freezesAvailable, 2);
    expect(streak.lastActivityDate!.toUtc(), DateTime.utc(2026, 9, 1));
    expect(streak.lastMercyDate!.toUtc(), DateTime.utc(2026, 8, 1));
    expect((await isarB.xpIsars.get(1))!.totalXp, 1234);
    final daily = await isarB.dailyActivityIsars.where().findAll();
    expect(daily.single.dayKey, 20260901);
    expect(daily.single.activityCount, 17);

    expect(prefsB.getString('read_pages'), '[1,2]');
    expect(prefsB.getString('user_profile'), userProfileA);
    expect(prefsB.getString('khatmah_active_plan'), khatmahPlanA);
    expect(prefsB.getString('khatmah_owner'), 'user-b');
    expect(prefsB.getString('mem_plus_kids_progress|user-b'), kidsProgressA);
    expect(prefsB.getString('mem_plus_home_missions|user-b'), homeMissionsA);
    expect(prefsB.getString('ramadan_tarawih|user-b'), '[{"night":1}]');
    expect(prefsB.getBool('ramadan_card_dismissed_start_1448|user-b'), true);
    expect(
      prefsB.getString('kids_reading_receipts_user-b'),
      '{"2026-09-08":[12]}',
    );
    expect(prefsB.getString('kids_streak_user-b'), '{"current":3}');
    expect(
      prefsB.getString('kids_achievements_user-b'),
      '{"first":"2026-09-01"}',
    );
    expect(prefsB.getStringList('kids_map_seen_completed_user-b_67'), [
      '1',
      '2',
    ]);
    expect(prefsB.getString('adult_journey_v1_user-b'), '{"v":1}');
    expect(prefsB.get('daily_wird_target_2026-09-08'), isA<int>());
    expect(prefsB.getInt('daily_wird_target_2026-09-08'), 12);
    expect(prefsB.get('hifz_pace'), isA<double>());
    expect(prefsB.getDouble('hifz_pace'), 1.5);
    expect(prefsB.getStringList('mem_plus_track_list'), ['a', 'b']);
    expect(prefsB.getKeys().where((k) => k.contains('user-a')), isEmpty);
  });

  test('parent settings and profile lose PIN, link state and foreign ids, '
      'on collect and on restore to a device without its own', () async {
    final isarA = await openIsar('sanitize_a');
    final payload = await collectA(isarA, await freshPrefs(ownerAPrefs()));
    final text = utf8.decode(gzip.decode(encodeBackup(payload)));
    for (final secret in [
      'pin-hash-secret',
      'pinHash',
      'child-id-secret',
      'guardian-id-secret',
      'policyLinkConfirmed',
    ]) {
      expect(text.contains(secret), isFalse, reason: secret);
    }

    // A crafted file that still carries them is sanitized on restore too.
    final crafted = BackupPayload(
      schemaVersion: payload.schemaVersion,
      createdAt: payload.createdAt,
      sections: {
        ...payload.sections,
        BackupSections.prefs: {
          ...(payload.sections[BackupSections.prefs]! as Map),
          'mem_plus_parent_settings|{owner}': {'t': 's', 'v': parentSettingsA},
          'mem_plus_profile': {'t': 's', 'v': profileA},
        },
      },
    );
    for (final p in [payload, crafted]) {
      final isarB = await openIsar('sanitize_b');
      final prefsB = await freshPrefs({});
      final result = await BackupRestorer(
        isarB,
        prefsB,
        const FixedRecordOwnerProvider('user-b'),
      ).restore(p);
      expect(result, BackupRestoreResult.restored);

      final settingsJson =
          jsonDecode(prefsB.getString('mem_plus_parent_settings|user-b')!)
              as Map<String, dynamic>;
      final settings = ParentSettingsModel.fromJson(settingsJson);
      // Target device had no parent settings: nothing of the file's PIN or
      // link state is taken (a device PIN is kept, see the group below).
      expect(settings.hasPin, isFalse);
      expect(settings.remoteLinkEnabled, isFalse);
      expect(settings.policySyncedVersion, 0);
      expect(settings.policyLinkConfirmed, isNull);
      expect(settings.reminderHour, 7);
      expect(settings.localChildNickname, 'Zaid');
      expect(settingsJson.containsKey('pinHash'), isFalse);

      final profile = MemorizationProfileModel.fromJson(
        jsonDecode(prefsB.getString('mem_plus_profile')!)
            as Map<String, dynamic>,
      );
      expect(profile.guardianLinkStatus, GuardianLinkStatus.none);
      expect(profile.guardianId, isNull);
      expect(profile.linkedChildId, isNull);
      expect(profile.isParentGuardian, isFalse);
      expect(profile.childAge, 8);
    }
  });

  test('payload over 64 KB round trips through multi-chunk gzip', () async {
    final isarA = await openIsar('big_a');
    await isarA.writeTxn(() async {
      await isarA.isarAyahReviewRecords.putAll([
        for (var ayah = 1; ayah <= 286; ayah++)
          _review(
            key: 'user-a|adult|2|$ayah',
            owner: 'user-a',
            audience: 'adult',
            surah: 2,
            ayah: ayah,
          ),
      ]);
    });
    // Incompressible text forces the compressed stream past 64 KB too.
    final random = Random(7);
    final noise = String.fromCharCodes([
      for (var i = 0; i < 120 * 1024; i++) 33 + random.nextInt(90),
    ]);
    final payload = await collectA(
      isarA,
      await freshPrefs({'mem_plus_blob|user-a': noise}),
    );
    final bytes = encodeBackup(payload);
    expect(bytes.length, greaterThan(64 * 1024));
    final decoded = decodeBackup(bytes);
    expect(decoded.error, isNull);
    expect(decoded.payload, payload);

    final isarB = await openIsar('big_b');
    final prefsB = await freshPrefs({});
    final result = await BackupRestorer(
      isarB,
      prefsB,
      const FixedRecordOwnerProvider('user-b'),
    ).restore(decoded.payload!);
    expect(result, BackupRestoreResult.restored);
    expect(await isarB.isarAyahReviewRecords.count(), 286);
    expect(prefsB.getString('mem_plus_blob|user-b'), noise);
  });

  test('collect excludes other owners keys/records, cloud/cursor/dirty keys '
      'and device settings', () async {
    final isar = await openIsar('excl');
    await seedOwnerA(isar);
    final prefs = await freshPrefs({
      ...ownerAPrefs(),
      // Other owners.
      'mem_plus_kids_progress|user-b': '{}',
      'ramadan_card_dismissed_end_1447|user-b': true,
      'ramadan_tarawih|user-b': '[]',
      'kids_reading_receipts_user-b': '{}',
      'kids_support_profile_user-b': '{}',
      'kids_family_practice_user-b': '{}',
      'kids_streak_user-ab': '{}',
      'kids_map_seen_completed_user-b_3': true,
      'kids_map_seen_completed_user-ab_3': true,
      'adult_journey_v1_user-b': '{}',
      // Bookmarks are not part of a v1 backup.
      'quran_bookmarks': '[]',
      'quran_bookmarks_owner_user-a': '[]',
      'quran_bookmarks_owner_user-a_migrated': true,
      // Unscoped legacy kids bases.
      'mem_plus_kids_progress': '{}',
      'mem_plus_parent_settings': '{}',
      'mem_plus_home_missions': '[]',
      // Quarantined corrupt payloads.
      'mem_plus_kids_progress|user-a|corrupt': 'garbage',
      'hifz_isar_migration_quarantine_1': 'garbage',
      // Sync bookkeeping, PIN, identity markers, pairing.
      'read_pages_cloud_dirty': true,
      'ayah_review_pull_cursor': '2026-08-01',
      'daily_plan_cloud_revision': 3,
      'custom_plan_cloud_conflict': '{}',
      'mem_plus_identity_cloud_dirty': true,
      'mem_plus_kids_legacy_cloud_floor|user-a': '{}',
      'mem_plus_parent_pin_hint': 'x',
      'mem_plus_local_records_claimed_by': 'user-a',
      'mem_plus_pairing_session': '{}',
      'khatmah_owner': 'user-a',
      // Device settings and flags.
      'theme_mode': 'dark',
      'app_locale': 'ar',
      'locale': 'ar',
      'notifications_enabled': true,
      'prayer_method': 'egypt',
      'prayer_companion_enabled': true,
      'experience_flag_ramadan': true,
      'kids_enrichment_t1': true,
      'clarity_mode_on': true,
      'bookmarks': '[]',
    });
    final payload = await collectA(isar, prefs);

    expect(payload.sections.keys.toSet(), BackupSections.all);
    final prefsSection = payload.sections[BackupSections.prefs]! as Map;
    expect(prefsSection.keys.toSet(), {
      'read_pages',
      'user_profile',
      'khatmah_active_plan',
      'mem_plus_kids_progress|{owner}',
      'mem_plus_home_missions|{owner}',
      'mem_plus_parent_settings|{owner}',
      'mem_plus_profile',
      'ramadan_tarawih|{owner}',
      'ramadan_card_dismissed_start_1448|{owner}',
      'kids_reading_receipts_{owner}',
      'kids_streak_{owner}',
      'kids_achievements_{owner}',
      'kids_map_seen_completed_{owner}_67',
      'adult_journey_v1_{owner}',
      'daily_wird_target_2026-09-08',
      'hifz_pace',
      'mem_plus_track_list',
    });
    expect(prefsSection['mem_plus_kids_progress|{owner}'], {
      't': 's',
      'v': kidsProgressA,
    });
    final reviews = payload.sections[BackupSections.reviewRecords]! as List;
    expect(reviews, hasLength(3));
    for (final row in reviews.cast<Map>()) {
      expect(row['ownerUserId'], kBackupOwnerToken);
      expect(row.containsKey('cloudDirty'), isFalse);
      expect(row.containsKey('lastSyncedAt'), isFalse);
    }
    expect(
      reviews.cast<Map>().map((r) => '${r['surahId']}:${r['ayahNumber']}'),
      unorderedEquals(['2:255', '114:6', '3:4']),
    );
    final text = utf8.decode(gzip.decode(encodeBackup(payload)));
    for (final id in ['user-a', 'user-b', 'user-z']) {
      expect(text.contains(id), isFalse, reason: id);
    }
  });

  /// user-b's device: own data, plus data a restore must never touch.
  Future<
    ({
      Isar isar,
      SharedPreferences prefs,
      _HookStore? store,
      Map<String, Object?> snap,
    })
  >
  ownerBDevice(String tag, {bool hooked = false}) async {
    final isar = await openIsar(tag);
    await isar.writeTxn(() async {
      await isar.isarAyahReviewRecords.putAll([
        _review(
          key: 'user-b|adult|5|5',
          owner: 'user-b',
          audience: 'adult',
          surah: 5,
          ayah: 5,
        ),
        _review(
          key: 'user-c|adult|1|1',
          owner: 'user-c',
          audience: 'adult',
          surah: 1,
          ayah: 1,
        ),
        // Null owner, identity key of another owner: not user-b's.
        _review(key: 'user-c|adult|1|4', owner: null, surah: 1, ayah: 4),
      ]);
      await isar.xpIsars.put(XpIsar()..totalXp = 99);
      await isar.cloudSyncQueueItems.putAll([
        _queue(CloudSyncQueueKind.productionPush, 'user-b')..attemptCount = 3,
        _queue(CloudSyncQueueKind.reviewEvidencePull, 'user-b'),
        _queue(CloudSyncQueueKind.bookmarkPush, 'user-b'),
        _queue(CloudSyncQueueKind.certificatePush, 'user-b'),
        _queue(CloudSyncQueueKind.productionPush, 'user-c'),
      ]);
      await isar.prayerCompanionRecordIsars.put(
        PrayerCompanionRecordIsar()
          ..occurrenceKey = 'user-b|2026-09-01|fajr'
          ..ownerId = 'user-b'
          ..localDayKey = 20260901
          ..prayerKeyIndex = 0
          ..scheduledAt = DateTime.utc(2026, 9, 1, 4)
          ..statusIndex = 0
          ..statusUpdatedAt = DateTime.utc(2026, 9, 1, 4)
          ..createdAt = DateTime.utc(2026, 9, 1, 4)
          ..updatedAt = DateTime.utc(2026, 9, 1, 4),
      );
    });
    final values = <String, Object>{
      'read_pages': '[600]',
      'azkar_counter_morning_z1': 3,
      'ramadan_tarawih|user-b': '[{"night":9}]',
      'ayah_review_pull_cursor': '2026-08-01',
      'ayah_review_pull_cursor_pulled_at': '2026-08-01',
      'quran_bookmarks': '[{"legacy":1}]',
      'quran_bookmarks_owner_user-b': '[{"s":2}]',
      'prayer_companion_enabled': true,
      'audio_resume_position': '{"surahId":67}',
      'last_restorable_location': '/quran/67',
      'ramadan_tarawih|user-c': '[{"night":2}]',
      'theme_mode': 'dark',
    };
    _HookStore? store;
    final SharedPreferences prefs;
    if (hooked) {
      final h = await hookedPrefs(values);
      prefs = h.prefs;
      store = h.store;
    } else {
      prefs = await freshPrefs(values);
    }
    return (isar: isar, prefs: prefs, store: store, snap: _prefsMap(prefs));
  }

  Future<BackupPayload> ownerAPayload() async {
    final isarA = await openIsar('src');
    await seedOwnerA(isarA);
    return collectA(isarA, await freshPrefs(ownerAPrefs()));
  }

  BackupPayload mutate(
    BackupPayload p,
    void Function(Map<String, Object?> sections) change,
  ) {
    final copy = decodeBackup(encodeBackup(p)).payload!;
    final sections = Map<String, Object?>.of(copy.sections);
    change(sections);
    return BackupPayload(
      schemaVersion: p.schemaVersion,
      createdAt: p.createdAt,
      sections: sections,
    );
  }

  Future<void> expectDeviceUntouched(
    ({
      Isar isar,
      SharedPreferences prefs,
      _HookStore? store,
      Map<String, Object?> snap,
    })
    env, {
    String? reason,
  }) async {
    final reviews = await env.isar.isarAyahReviewRecords.where().findAll();
    expect(reviews.map((r) => r.compositeKey).toSet(), {
      'user-b|adult|5|5',
      'user-c|adult|1|1',
      'user-c|adult|1|4',
    }, reason: reason);
    expect((await env.isar.xpIsars.get(1))!.totalXp, 99, reason: reason);
    final queue = await env.isar.cloudSyncQueueItems.where().findAll();
    expect(queue.map((q) => '${q.ownerUserId}/${q.kind}/${q.attemptCount}'), {
      'user-b/${CloudSyncQueueKind.productionPush}/3',
      'user-b/${CloudSyncQueueKind.reviewEvidencePull}/0',
      'user-b/${CloudSyncQueueKind.bookmarkPush}/0',
      'user-b/${CloudSyncQueueKind.certificatePush}/0',
      'user-c/${CloudSyncQueueKind.productionPush}/0',
    }, reason: reason);
    expect(_prefsMap(env.prefs), env.snap, reason: reason);
  }

  test(
    'invalid section (surah 115) → invalidSections and existing data untouched',
    () async {
      final good = await ownerAPayload();
      final invalid = <String, BackupPayload>{
        'surah 115': mutate(good, (s) {
          ((s[BackupSections.reviewRecords]! as List).first as Map)['surahId'] =
              115;
        }),
        'ayah past surah end': mutate(good, (s) {
          ((s[BackupSections.ayahProgress]! as List).first
                  as Map)['ayahNumber'] =
              8;
        }),
        'impossible dayKey': mutate(good, (s) {
          ((s[BackupSections.dailyActivity]! as List).first as Map)['dayKey'] =
              20260231;
        }),
        'negative xp': mutate(good, (s) {
          (s[BackupSections.xp]! as Map)['totalXp'] = -1;
        }),
        'device key in prefs': mutate(good, (s) {
          (s[BackupSections.prefs]! as Map)['theme_mode'] = {
            't': 's',
            'v': 'light',
          };
        }),
        'bookmark key in prefs': mutate(good, (s) {
          (s[BackupSections.prefs]! as Map)['quran_bookmarks'] = {
            't': 's',
            'v': '[]',
          };
        }),
        'raw owner id in prefs key': mutate(good, (s) {
          (s[BackupSections.prefs]! as Map)['ramadan_tarawih|user-x'] = {
            't': 's',
            'v': '[]',
          };
        }),
        'missing section': mutate(good, (s) => s.remove(BackupSections.xp)),
      };

      for (final entry in invalid.entries) {
        final env = await ownerBDevice('inv_${entry.key.hashCode}');
        final result = await BackupRestorer(
          env.isar,
          env.prefs,
          const FixedRecordOwnerProvider('user-b'),
        ).restore(entry.value);
        expect(result, BackupRestoreResult.invalidSections, reason: entry.key);
        await expectDeviceUntouched(env, reason: entry.key);
      }
    },
  );

  test('restore replaces this owner\'s backed-up data and leaves PIN, '
      'bookmarks, prayer companion, other owners and device data', () async {
    final payload = await ownerAPayload();
    final env = await ownerBDevice('replace');
    final pins = _MemoryPinStore()..verifiers['user-b'] = 'verifier-b';
    final result = await BackupRestorer(
      env.isar,
      env.prefs,
      const FixedRecordOwnerProvider('user-b'),
    ).restore(payload);
    expect(result, BackupRestoreResult.restored);

    // Replaced.
    final keys = (await env.isar.isarAyahReviewRecords.where().findAll())
        .map((r) => r.compositeKey)
        .toSet();
    expect(keys, isNot(contains('user-b|adult|5|5')));
    expect(keys, contains('user-b|adult|2|255'));
    expect((await env.isar.xpIsars.get(1))!.totalXp, 1234);
    expect(env.prefs.getString('read_pages'), '[1,2]');
    expect(env.prefs.containsKey('azkar_counter_morning_z1'), isFalse);
    expect(env.prefs.getString('ramadan_tarawih|user-b'), '[{"night":1}]');
    expect(env.prefs.containsKey('ayah_review_pull_cursor'), isFalse);
    expect(env.prefs.containsKey('ayah_review_pull_cursor_pulled_at'), isFalse);
    // Review/production queue work is replaced by one fresh production push
    // for the dirty restored rows; other kinds and owners stay queued.
    final queue = await env.isar.cloudSyncQueueItems.where().findAll();
    expect(queue.map((q) => '${q.ownerUserId}/${q.kind}/${q.attemptCount}'), {
      'user-b/${CloudSyncQueueKind.productionPush}/0',
      'user-b/${CloudSyncQueueKind.bookmarkPush}/0',
      'user-b/${CloudSyncQueueKind.certificatePush}/0',
      'user-c/${CloudSyncQueueKind.productionPush}/0',
    });

    // Untouched.
    expect(keys, contains('user-c|adult|1|1'));
    expect(keys, contains('user-c|adult|1|4'));
    expect(await env.isar.prayerCompanionRecordIsars.count(), 1);
    expect(await pins.readVerifier('user-b'), 'verifier-b');
    for (final key in [
      'quran_bookmarks',
      'quran_bookmarks_owner_user-b',
      'prayer_companion_enabled',
      'audio_resume_position',
      'last_restorable_location',
      'ramadan_tarawih|user-c',
      'theme_mode',
    ]) {
      expect(env.prefs.get(key), env.snap[key], reason: key);
    }
  });

  group('device PIN and link state survive a restore', () {
    final deviceSettings = jsonEncode({
      'pinHash': 'device-pin-marker',
      'reminderHour': 20,
      'remoteLinkEnabled': true,
      'policyVersion': 2,
      'policySyncedVersion': 2,
      'policyLinkConfirmed': false,
    });
    final deviceProfile = jsonEncode({
      'schemaVersion': 1,
      'selectedPath': 'child',
      'guardianLinkStatus': 'linked',
      'guardianOnboardingStatus': 'completed',
      'guardianId': 'device-guardian',
      'isParentGuardian': false,
      'childAge': 6,
    });

    Future<SharedPreferences> pinnedDevice({String owner = 'user-b'}) =>
        freshPrefs({
          'mem_plus_parent_settings|$owner': deviceSettings,
          'mem_plus_profile': deviceProfile,
          'mem_plus_is_parent_mode': false,
          'read_pages': '[600]',
        });

    Future<BackupRestoreResult> restoreAs(
      SharedPreferences prefs,
      BackupPayload payload, {
      String owner = 'user-b',
    }) async => BackupRestorer(
      await openIsar('pin_${prefs.hashCode}'),
      prefs,
      FixedRecordOwnerProvider(owner),
    ).restore(payload);

    test('backup with parent settings and profile: device fields kept, '
        'backed-up fields restored', () async {
      final prefs = await pinnedDevice();
      final result = await restoreAs(prefs, await ownerAPayload());
      expect(result, BackupRestoreResult.restored);

      final settings = ParentSettingsModel.fromJson(
        jsonDecode(prefs.getString('mem_plus_parent_settings|user-b')!)
            as Map<String, dynamic>,
      );
      expect(settings.hasPin, isTrue);
      expect(settings.pinHash, 'device-pin-marker');
      expect(settings.remoteLinkEnabled, isTrue);
      expect(settings.policySyncedVersion, 2);
      expect(settings.policyLinkConfirmed, isFalse);
      // From the file.
      expect(settings.reminderHour, 7);
      expect(settings.localChildNickname, 'Zaid');
      expect(settings.policyVersion, 4);

      final profile = MemorizationProfileModel.fromJson(
        jsonDecode(prefs.getString('mem_plus_profile')!)
            as Map<String, dynamic>,
      );
      expect(profile.guardianLinkStatus, GuardianLinkStatus.linked);
      expect(profile.guardianId, 'device-guardian');
      expect(profile.linkedChildId, isNull);
      expect(
        profile.guardianOnboardingStatus,
        GuardianOnboardingStatus.completed,
      );
      expect(profile.isParentGuardian, isFalse);
      // From the file.
      expect(profile.childAge, 8);
      expect(prefs.getBool('mem_plus_is_parent_mode'), isFalse);
      expect(prefs.getString('read_pages'), '[1,2]');
    });

    test('backup without parent settings or profile leaves the device '
        'values untouched', () async {
      final payload = mutate(await ownerAPayload(), (s) {
        final prefs = {...(s[BackupSections.prefs]! as Map)};
        prefs.remove('mem_plus_parent_settings|{owner}');
        prefs.remove('mem_plus_profile');
        s[BackupSections.prefs] = prefs;
      });
      final prefs = await pinnedDevice();
      expect(await restoreAs(prefs, payload), BackupRestoreResult.restored);
      expect(
        prefs.getString('mem_plus_parent_settings|user-b'),
        deviceSettings,
      );
      expect(prefs.getString('mem_plus_profile'), deviceProfile);
      expect(prefs.getString('read_pages'), '[1,2]');
    });

    test('guest owner: the legacy unscoped PIN is carried into the restored '
        'scoped settings', () async {
      final prefs = await freshPrefs({
        'mem_plus_parent_settings': deviceSettings,
      });
      expect(
        await restoreAs(prefs, await ownerAPayload(), owner: 'local'),
        BackupRestoreResult.restored,
      );
      final settings = ParentSettingsModel.fromJson(
        jsonDecode(prefs.getString('mem_plus_parent_settings|local')!)
            as Map<String, dynamic>,
      );
      expect(settings.pinHash, 'device-pin-marker');
      expect(settings.reminderHour, 7);
    });

    test('parent-mode flag is device-local: never collected, and an older '
        'file carrying it is restored without it', () async {
      final isarA = await openIsar('mode_a');
      final payload = await collectA(
        isarA,
        await freshPrefs({...ownerAPrefs(), 'mem_plus_is_parent_mode': true}),
      );
      final prefsSection = payload.sections[BackupSections.prefs]! as Map;
      expect(prefsSection.containsKey('mem_plus_is_parent_mode'), isFalse);

      final older = mutate(payload, (s) {
        s[BackupSections.prefs] = {
          ...(s[BackupSections.prefs]! as Map),
          'mem_plus_is_parent_mode': {'t': 'b', 'v': true},
        };
      });
      final prefs = await pinnedDevice();
      expect(await restoreAs(prefs, older), BackupRestoreResult.restored);
      expect(prefs.getBool('mem_plus_is_parent_mode'), isFalse);
    });
  });

  test('owner switch before the write: writeFailed and nothing written for '
      'either owner', () async {
    final payload = await ownerAPayload();
    final env = await ownerBDevice('switch_before');
    final owner = _SwitchingOwner('user-b', 'user-c');
    final result = await BackupRestorer(
      env.isar,
      env.prefs,
      owner,
    ).restore(payload);
    expect(result, BackupRestoreResult.writeFailed);
    await expectDeviceUntouched(env);
  });

  test('owner switch mid-restore with the switch reset queued: no rollback, '
      'and user-c sees none of user-b data', () async {
    final payload = await ownerAPayload();
    final env = await ownerBDevice('switch_mid', hooked: true);
    final owner = _MutableOwner('user-b');
    AccountDataBarrier.forPreferences(env.prefs).owner = owner;
    final reset = AccountDataReset(env.isar, env.prefs, owner: owner);
    Future<void>? switchReset;
    env.store!.onSet = (key) {
      // The account switch lands mid-restore and queues its reset, as
      // AuthCubit does through resolveOwnerChange.
      if (switchReset == null) {
        owner.currentOwnerId = 'user-c';
        switchReset = reset.clearAccountOwnedData(departingOwnerId: 'user-b');
      }
      return true;
    };
    final events = ProgressEventsBus();
    final reasons = <ProgressChangedReason>[];
    final sub = events.changes.listen(reasons.add);
    final result = await BackupRestorer(
      env.isar,
      env.prefs,
      owner,
      events: events,
    ).restore(payload);
    await switchReset;
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(result, BackupRestoreResult.writeFailed);
    expect(reasons, [ProgressChangedReason.cloudPull]);

    for (final key in [
      'read_pages',
      'user_profile',
      'khatmah_active_plan',
      'khatmah_owner',
      'mem_plus_profile',
      'mem_plus_kids_progress|user-b',
      'ramadan_tarawih|user-b',
      'hifz_pace',
      'daily_wird_target_2026-09-08',
      'ayah_review_pull_cursor',
      // Not owned by AccountDataReset: only "no rollback" keeps it away.
      'azkar_counter_morning_z1',
    ]) {
      expect(env.prefs.containsKey(key), isFalse, reason: key);
    }
    final stored = await env.store!.getAll();
    expect(stored.containsKey('flutter.read_pages'), isFalse);
    expect(stored.containsKey('flutter.khatmah_active_plan'), isFalse);
    expect(await env.isar.isarAyahProgress.count(), 0);
    expect(await env.isar.streakIsars.count(), 0);
    expect(await env.isar.xpIsars.count(), 0);
    expect(await env.isar.dailyActivityIsars.count(), 0);
    final reviews = await env.isar.isarAyahReviewRecords.where().findAll();
    expect(
      reviews.where((r) => r.ownerUserId == 'user-b' || r.ownerUserId == null),
      isEmpty,
    );
  });

  test('a barrier writer queued behind a failing restore is not undone by '
      'the rollback', () async {
    final payload = await ownerAPayload();
    final env = await ownerBDevice('queued_writer', hooked: true);
    final barrier = AccountDataBarrier.forPreferences(env.prefs);
    Future<void>? writer;
    env.store!.onSet = (key) {
      if (key == 'ramadan_tarawih|user-b' && writer == null) {
        writer = barrier.run((_) async {
          await env.prefs.setString('read_pages', '[777]');
          await env.isar.writeTxn(
            () => env.isar.xpIsars.put(XpIsar()..totalXp = 555),
          );
        });
        return false;
      }
      return true;
    };
    final result = await BackupRestorer(
      env.isar,
      env.prefs,
      const FixedRecordOwnerProvider('user-b'),
    ).restore(payload);
    await writer;
    expect(result, BackupRestoreResult.writeFailed);
    expect(env.prefs.getString('read_pages'), '[777]');
    expect((await env.store!.getAll())['flutter.read_pages'], '[777]');
    expect((await env.isar.xpIsars.get(1))!.totalXp, 555);
    // Everything else is rolled back.
    expect(env.prefs.getString('ramadan_tarawih|user-b'), '[{"night":9}]');
    expect(env.prefs.containsKey('khatmah_active_plan'), isFalse);
    final reviews = await env.isar.isarAyahReviewRecords.where().findAll();
    expect(reviews.map((r) => r.compositeKey).toSet(), {
      'user-b|adult|5|5',
      'user-c|adult|1|1',
      'user-c|adult|1|4',
    });
  });

  test('prefs write failure mid-restore: writeFailed and original data '
      'back', () async {
    final payload = await ownerAPayload();
    final env = await ownerBDevice('prefs_fail', hooked: true);
    var failed = false;
    env.store!.onSet = (key) {
      if (key == 'ramadan_tarawih|user-b' && !failed) {
        failed = true;
        return false;
      }
      return true;
    };
    final events = ProgressEventsBus();
    final reasons = <ProgressChangedReason>[];
    final sub = events.changes.listen(reasons.add);
    final result = await BackupRestorer(
      env.isar,
      env.prefs,
      const FixedRecordOwnerProvider('user-b'),
      events: events,
    ).restore(payload);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(failed, isTrue);
    expect(result, BackupRestoreResult.writeFailed);
    expect(reasons, [ProgressChangedReason.cloudPull]);
    await expectDeviceUntouched(env);
    // The store, not just the in-memory cache, holds the original values.
    final stored = await env.store!.getAll();
    expect(stored['flutter.read_pages'], '[600]');
    expect(stored['flutter.ramadan_tarawih|user-b'], '[{"night":9}]');
    expect(stored.containsKey('flutter.khatmah_active_plan'), isFalse);
  });

  test('v2 backup round-trips private note text and timestamps under the new owner',
      () async {
    final created = DateTime.utc(2026, 10, 1, 6, 30);
    final updated = DateTime.utc(2026, 10, 2, 7, 45);
    final isarA = await openIsar('notes_v2_source');
    await isarA.writeTxn(() => isarA.isarAyahNotes.putAll([
          IsarAyahNote()
            ..ownerId = 'user-a'
            ..surahId = 2
            ..ayahNumber = 255
            ..body = 'Private note: e\u{301} 👩🏽‍💻'
            ..createdAt = created
            ..updatedAt = updated,
          IsarAyahNote()
            ..ownerId = 'user-c'
            ..surahId = 1
            ..ayahNumber = 1
            ..body = 'Other owner'
            ..createdAt = created
            ..updatedAt = updated,
        ]));
    final payload = await collectA(isarA, await freshPrefs(ownerAPrefs()));
    final notes = payload.sections[BackupSections.ayahNotes]! as List;
    expect(notes, hasLength(1));
    expect((notes.single as Map)['ownerId'], kBackupOwnerToken);
    expect((notes.single as Map).containsKey('id'), isFalse);

    final isarB = await openIsar('notes_v2_target');
    await isarB.writeTxn(() => isarB.isarAyahNotes.put(
          IsarAyahNote()
            ..ownerId = 'user-c'
            ..surahId = 1
            ..ayahNumber = 1
            ..body = 'Keep private C'
            ..createdAt = created
            ..updatedAt = updated,
        ));
    expect(
      await BackupRestorer(
        isarB,
        await freshPrefs({}),
        const FixedRecordOwnerProvider('user-b'),
      ).restore(payload),
      BackupRestoreResult.restored,
    );
    final restored = await isarB.isarAyahNotes
        .filter()
        .ownerIdEqualTo('user-b')
        .findAll();
    expect(restored, hasLength(1));
    expect(restored.single.body, 'Private note: e\u{301} 👩🏽‍💻');
    expect(restored.single.createdAt.toUtc(), created);
    expect(restored.single.updatedAt.toUtc(), updated);
    expect(
      (await isarB.isarAyahNotes.filter().ownerIdEqualTo('user-c').findAll())
          .single
          .body,
      'Keep private C',
    );
  });

  test('a v1 backup keeps the notes it cannot carry; note section validation is strict',
      () async {
    final source = await openIsar('notes_v1_source');
    final v2 = await collectA(source, await freshPrefs(ownerAPrefs()));
    final decoded = decodeBackup(
      await File('test/fixtures/backups/pre_ayah_notes_v1.talia').readAsBytes(),
    );
    expect(decoded.error, isNull);
    expect(decoded.payload!.schemaVersion, 1);
    final v1 = decoded.payload!;
    final target = await openIsar('notes_v1_target');
    final stamp = DateTime.utc(2026, 10, 1);
    await target.writeTxn(() => target.isarAyahNotes.putAll([
          IsarAyahNote()
            ..ownerId = 'user-b'
            ..surahId = 1
            ..ayahNumber = 1
            ..body = 'Replace me'
            ..createdAt = stamp
            ..updatedAt = stamp,
          IsarAyahNote()
            ..ownerId = 'user-c'
            ..surahId = 1
            ..ayahNumber = 1
            ..body = 'Keep me'
            ..createdAt = stamp
            ..updatedAt = stamp,
        ]));
    final prefs = await freshPrefs({});
    final restorer = BackupRestorer(
      target,
      prefs,
      const FixedRecordOwnerProvider('user-b'),
    );
    expect(await restorer.restore(v1), BackupRestoreResult.restored);
    // A pre-notes backup has no notes section: the device's notes survive.
    expect(
      (await target.isarAyahNotes.filter().ownerIdEqualTo('user-b').findFirst())!
          .body,
      'Replace me',
    );
    expect(
      (await target.isarAyahNotes.filter().ownerIdEqualTo('user-c').findFirst())!
          .body,
      'Keep me',
    );

    final missing = BackupPayload(
      schemaVersion: 2,
      createdAt: v2.createdAt,
      sections: {
        for (final entry in v2.sections.entries)
          if (entry.key != BackupSections.ayahNotes) entry.key: entry.value,
      },
    );
    final duplicate = BackupPayload(
      schemaVersion: 2,
      createdAt: v2.createdAt,
      sections: {
        ...v2.sections,
        BackupSections.ayahNotes: [
          {
            'ownerId': kBackupOwnerToken,
            'surahId': 1,
            'ayahNumber': 1,
            'body': 'one',
            'createdAt': stamp.toIso8601String(),
            'updatedAt': stamp.toIso8601String(),
          },
          {
            'ownerId': kBackupOwnerToken,
            'surahId': 1,
            'ayahNumber': 1,
            'body': 'two',
            'createdAt': stamp.toIso8601String(),
            'updatedAt': stamp.toIso8601String(),
          },
        ],
      },
    );
    final corrupt = BackupPayload(
      schemaVersion: 2,
      createdAt: v2.createdAt,
      sections: {
        ...v2.sections,
        BackupSections.ayahNotes: [
          {
            'ownerId': kBackupOwnerToken,
            'surahId': 1,
            'ayahNumber': 1,
            'body': '   ',
            'createdAt': stamp.toIso8601String(),
            'updatedAt': stamp.toIso8601String(),
          },
        ],
      },
    );
    final v1WithNotes = BackupPayload(
      schemaVersion: 1,
      createdAt: v2.createdAt,
      sections: v2.sections,
    );
    expect(await restorer.restore(missing), BackupRestoreResult.invalidSections);
    expect(await restorer.restore(duplicate), BackupRestoreResult.invalidSections);
    expect(await restorer.restore(corrupt), BackupRestoreResult.invalidSections);
    expect(
      await restorer.restore(v1WithNotes),
      BackupRestoreResult.invalidSections,
    );
  });

  test('corrupt local notes fail collection and preference rollback restores notes',
      () async {
    final source = await openIsar('notes_corrupt_source');
    final stamp = DateTime.utc(2026, 10, 1);
    await source.writeTxn(() => source.isarAyahNotes.put(
          IsarAyahNote()
            ..ownerId = 'user-a'
            ..surahId = 115
            ..ayahNumber = 1
            ..body = 'invalid reference'
            ..createdAt = stamp
            ..updatedAt = stamp,
        ));
    await expectLater(
      collectA(source, await freshPrefs(ownerAPrefs())),
      throwsA(isA<StateError>()),
    );

    final importSource = await openIsar('notes_rollback_source');
    await importSource.writeTxn(() => importSource.isarAyahNotes.put(
          IsarAyahNote()
            ..ownerId = 'user-a'
            ..surahId = 2
            ..ayahNumber = 255
            ..body = 'Imported note'
            ..createdAt = stamp
            ..updatedAt = stamp,
        ));
    final payload = await collectA(importSource, await freshPrefs(ownerAPrefs()));
    final env = await ownerBDevice('notes_rollback', hooked: true);
    await env.isar.writeTxn(() => env.isar.isarAyahNotes.putAll([
          IsarAyahNote()
            ..ownerId = 'user-b'
            ..surahId = 1
            ..ayahNumber = 1
            ..body = 'Original B'
            ..createdAt = stamp
            ..updatedAt = stamp,
          IsarAyahNote()
            ..ownerId = 'user-c'
            ..surahId = 1
            ..ayahNumber = 1
            ..body = 'Private C'
            ..createdAt = stamp
            ..updatedAt = stamp,
        ]));
    env.store!.onSet = (key) => key != 'ramadan_tarawih|user-b';
    expect(
      await BackupRestorer(
        env.isar,
        env.prefs,
        const FixedRecordOwnerProvider('user-b'),
      ).restore(payload),
      BackupRestoreResult.writeFailed,
    );
    expect(
      (await env.isar.isarAyahNotes.filter().ownerIdEqualTo('user-b').findAll())
          .single
          .body,
      'Original B',
    );
    expect(
      (await env.isar.isarAyahNotes.filter().ownerIdEqualTo('user-c').findAll())
          .single
          .body,
      'Private C',
    );
  });

  test('azkar counters travel with their day stamp: a yesterday backup reads '
      'as zero today', () async {
    final today = DateTime(2026, 10, 17, 9);
    final yesterday = DateTime(2026, 10, 16, 9);
    final isarA = await openIsar('azkar_a');
    final prefsA = await freshPrefs({});
    final storeA = AzkarCompletionStore(prefsA, now: () => yesterday);
    await storeA.prepareForToday(AzkarCategory.morning);
    await storeA.setCount(
      category: AzkarCategory.morning,
      zikrId: 'z1',
      count: 3,
    );
    expect(storeA.countFor(AzkarCategory.morning, 'z1'), 3);
    final payload = await collectA(isarA, prefsA);

    final isarB = await openIsar('azkar_b');
    final prefsB = await freshPrefs({});
    final storeB = AzkarCompletionStore(prefsB, now: () => today);
    await storeB.prepareForToday(AzkarCategory.morning);
    expect(storeB.isToday(AzkarCategory.morning), isTrue);
    final result = await BackupRestorer(
      isarB,
      prefsB,
      const FixedRecordOwnerProvider('user-b'),
    ).restore(payload);
    expect(result, BackupRestoreResult.restored);
    expect(storeB.countFor(AzkarCategory.morning, 'z1'), 0);
    expect(
      AzkarCompletionStore(
        prefsB,
        now: () => yesterday,
      ).countFor(AzkarCategory.morning, 'z1'),
      3,
    );
  });

  group('external review fixes (group A)', () {
    final validPlan = jsonEncode({
      'id': 'p1',
      'title': 'Khatmah',
      'startPage': 1,
      'completedPages': [1, 2],
      'targetPagesPerDay': 20,
      'targetDays': 30,
      'startDate': '2026-09-01T00:00:00.000Z',
      'expectedEndDate': '2026-09-30T00:00:00.000Z',
    });

    test('A1: a reset that lands while collecting invalidates the backup: '
        'collect throws and yields no payload', () async {
      final isar = await openIsar('a1');
      await seedOwnerA(isar);
      final prefs = await freshPrefs(ownerAPrefs());
      final reset = AccountDataReset(isar, prefs);
      final collect = BackupCollector(
        isar,
        prefs,
        const FixedRecordOwnerProvider('user-a'),
      ).collect(DateTime.utc(2026, 10, 17));
      final cleared = reset.clearAccountOwnedData();
      Object? error;
      BackupPayload? payload;
      try {
        payload = await collect;
      } catch (e) {
        error = e;
      }
      await cleared;
      expect(payload, isNull);
      expect(error, isA<AccountDataUnavailableException>());
    });

    test('A2: malformed domain JSON or a wrong wrapper type → '
        'invalidSections and nothing written', () async {
      final good = await ownerAPayload();
      BackupPayload withPref(String key, Map<String, Object?> value) =>
          mutate(good, (s) {
            s[BackupSections.prefs] = {
              ...(s[BackupSections.prefs]! as Map),
              key: value,
            };
          });
      final invalid = <String, BackupPayload>{
        'khatmah plan missing fields': withPref('khatmah_active_plan', {
          't': 's',
          'v': '{"id":"p1"}',
        }),
        'khatmah plan not JSON': withPref('khatmah_active_plan', {
          't': 's',
          'v': 'not json',
        }),
        'khatmah history not a list': withPref('khatmah_history', {
          't': 's',
          'v': '{"id":"h1"}',
        }),
        'read_pages as int wrapper': withPref('read_pages', {'t': 'i', 'v': 3}),
        'read_pages as plain string': withPref('read_pages', {
          't': 's',
          'v': 'pages',
        }),
        'user_profile wrong age type': withPref('user_profile', {
          't': 's',
          'v': '{"name":"A","age":"x"}',
        }),
        'mem_plus_profile wrong field type': withPref('mem_plus_profile', {
          't': 's',
          'v': '{"isParentGuardian":"yes"}',
        }),
        'parent settings wrong field type': withPref(
          'mem_plus_parent_settings|{owner}',
          {'t': 's', 'v': '{"reminderHour":"seven"}'},
        ),
        'parent rewards not a list': withPref(
          'mem_plus_parent_rewards|{owner}',
          {'t': 's', 'v': '{"id":"r1"}'},
        ),
        'session logs not JSON': withPref(
          'mem_plus_kids_session_logs|{owner}',
          {'t': 's', 'v': 'garbage'},
        ),
        'azkar counter as string': withPref('azkar_counter_morning_z1', {
          't': 's',
          'v': '3',
        }),
      };
      for (final entry in invalid.entries) {
        final env = await ownerBDevice('a2_${entry.key.hashCode}');
        await env.prefs.setString('khatmah_active_plan', validPlan);
        final snap = _prefsMap(env.prefs);
        final result = await BackupRestorer(
          env.isar,
          env.prefs,
          const FixedRecordOwnerProvider('user-b'),
        ).restore(entry.value);
        expect(result, BackupRestoreResult.invalidSections, reason: entry.key);
        expect(env.prefs.getString('khatmah_active_plan'), validPlan);
        expect(_prefsMap(env.prefs), snap, reason: entry.key);
      }
    });

    test('A2: collect skips a corrupt local value instead of producing an '
        'unrestorable backup', () async {
      final isar = await openIsar('a2_collect');
      final payload = await collectA(
        isar,
        await freshPrefs({...ownerAPrefs(), 'khatmah_history': 'garbage'}),
      );
      final prefsSection = payload.sections[BackupSections.prefs]! as Map;
      expect(prefsSection.containsKey('khatmah_history'), isFalse);
      expect(prefsSection.containsKey('khatmah_active_plan'), isTrue);
      final result = await BackupRestorer(
        await openIsar('a2_collect_b'),
        await freshPrefs({}),
        const FixedRecordOwnerProvider('user-b'),
      ).restore(payload);
      expect(result, BackupRestoreResult.restored);
    });

    String log(String id) => jsonEncode({
      'id': id,
      'surahId': 112,
      'ayahNumber': 1,
      'repeatsCompleted': 3,
      'pointsEarned': 10,
      'completedAt': '2026-09-01T00:00:00.000Z',
    });
    String reward(String id) => jsonEncode({
      'id': id,
      'title': 'Gift $id',
      'status': 0,
      'createdAt': '2026-09-01T00:00:00.000Z',
    });

    test('A2 review: collect drops a corrupt session log item and keeps the '
        'good ones', () async {
      final isar = await openIsar('a2_items_collect');
      final payload = await collectA(
        isar,
        await freshPrefs({
          ...ownerAPrefs(),
          'mem_plus_kids_session_logs|user-a':
              '[${log('l1')},{"id":"bad"},${log('l3')}]',
        }),
      );
      final prefsSection = payload.sections[BackupSections.prefs]! as Map;
      final value =
          (prefsSection['mem_plus_kids_session_logs|{owner}'] as Map)['v']
              as String;
      final ids = [
        for (final item in jsonDecode(value) as List) (item as Map)['id'],
      ];
      expect(ids, ['l1', 'l3']);
    });

    test('A2 review: restore keeps the good rewards of a list with one bad '
        'item', () async {
      final payload = mutate(await ownerAPayload(), (s) {
        s[BackupSections.prefs] = {
          ...(s[BackupSections.prefs]! as Map),
          'mem_plus_parent_rewards|{owner}': {
            't': 's',
            'v': '[${reward('r1')},{"id":"bad"},${reward('r3')}]',
          },
        };
      });
      final prefsB = await freshPrefs({});
      final result = await BackupRestorer(
        await openIsar('a2_items_restore'),
        prefsB,
        const FixedRecordOwnerProvider('user-b'),
      ).restore(payload);
      expect(result, BackupRestoreResult.restored);
      final rewards =
          jsonDecode(prefsB.getString('mem_plus_parent_rewards|user-b')!)
              as List;
      expect([for (final r in rewards) (r as Map)['id']], ['r1', 'r3']);
    });

    test('A3: a linked child profile restored to a device without a profile '
        'needs guardian onboarding again', () async {
      final linkedChild = jsonEncode({
        'schemaVersion': 1,
        'selectedPath': 'child',
        'guardianLinkStatus': 'linked',
        'guardianOnboardingStatus': 'completed',
        'guardianId': 'guardian-id-secret',
        'linkedChildId': 'child-id-secret',
        'isParentGuardian': true,
        'childAge': 7,
      });
      final isarA = await openIsar('a3_a');
      final payload = await collectA(
        isarA,
        await freshPrefs({...ownerAPrefs(), 'mem_plus_profile': linkedChild}),
      );
      final prefsB = await freshPrefs({});
      final result = await BackupRestorer(
        await openIsar('a3_b'),
        prefsB,
        const FixedRecordOwnerProvider('user-b'),
      ).restore(payload);
      expect(result, BackupRestoreResult.restored);
      final datasource = MemorizationPlusLocalDatasourceImpl(
        prefsB,
        owner: const FixedRecordOwnerProvider('user-b'),
      );
      final profile = await datasource.getMemorizationProfile();
      expect(profile.isChild, isTrue);
      expect(profile.guardianLinkStatus, GuardianLinkStatus.none);
      expect(profile.isParentGuardian, isFalse);
      expect(profile.needsGuardianOnboarding, isTrue);
    });
  });
}
