import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/backup_collector.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';
import 'package:talia_quran/core/backup/backup_restorer.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/streak/data/models/daily_activity_isar.dart';
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';
import 'package:talia_quran/features/xp/data/models/xp_isar.dart';

import '../../helpers/isar_test_core.dart';

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

  const ownerAPrefs = <String, Object>{
    'read_pages': '[1,2]',
    'user_profile': 'Ahmad',
    'khatmah_active_plan': '{"id":"p1"}',
    'mem_plus_kids_progress|user-a': '{"stars":3}',
    'mem_plus_home_missions|user-a': '[{"id":"m1"}]',
    'ramadan_tarawih|user-a': '[{"night":1}]',
    'ramadan_card_dismissed_start_1448|user-a': true,
    'kids_reading_receipts_user-a': '{"2026-09-08":[12]}',
    'adult_journey_v1_user-a': '{"v":1}',
    'quran_bookmarks_owner_user-a': '[{"s":1}]',
    'quran_bookmarks_owner_user-a_migrated': true,
    'daily_wird_target_2026-09-08': 12,
    'hifz_pace': 1.5,
    'mem_plus_track_list': <String>['a', 'b'],
  };

  test('collect → encode → decode → restore under ANOTHER owner reproduces '
      'records with the new owner', () async {
    final isarA = await openIsar('a');
    await seedOwnerA(isarA);
    final prefsA = await freshPrefs(ownerAPrefs);
    final payload = await BackupCollector(
      isarA,
      prefsA,
      const FixedRecordOwnerProvider('user-a'),
    ).collect(DateTime.utc(2026, 10, 17));

    final bytes = encodeBackup(payload);
    final decoded = decodeBackup(bytes);
    expect(decoded.error, isNull);

    final isarB = await openIsar('b');
    final prefsB = await freshPrefs({});
    const ownerB = FixedRecordOwnerProvider('user-b');
    final events = ProgressEventsBus();
    final reasons = <ProgressChangedReason>[];
    final sub = events.changes.listen(reasons.add);
    final result = await BackupRestorer(
      isarB,
      prefsB,
      ownerB,
      AccountDataReset(isarB, prefsB, owner: ownerB),
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
    expect(prefsB.getString('user_profile'), 'Ahmad');
    expect(prefsB.getString('khatmah_active_plan'), '{"id":"p1"}');
    expect(prefsB.getString('khatmah_owner'), 'user-b');
    expect(prefsB.getString('mem_plus_kids_progress|user-b'), '{"stars":3}');
    expect(prefsB.getString('mem_plus_home_missions|user-b'), '[{"id":"m1"}]');
    expect(prefsB.getString('ramadan_tarawih|user-b'), '[{"night":1}]');
    expect(prefsB.getBool('ramadan_card_dismissed_start_1448|user-b'), true);
    expect(
      prefsB.getString('kids_reading_receipts_user-b'),
      '{"2026-09-08":[12]}',
    );
    expect(prefsB.getString('adult_journey_v1_user-b'), '{"v":1}');
    expect(prefsB.getString('quran_bookmarks_owner_user-b'), '[{"s":1}]');
    expect(prefsB.getBool('quran_bookmarks_owner_user-b_migrated'), true);
    expect(prefsB.get('daily_wird_target_2026-09-08'), isA<int>());
    expect(prefsB.getInt('daily_wird_target_2026-09-08'), 12);
    expect(prefsB.get('hifz_pace'), isA<double>());
    expect(prefsB.getDouble('hifz_pace'), 1.5);
    expect(prefsB.getStringList('mem_plus_track_list'), ['a', 'b']);
    expect(prefsB.getKeys().where((k) => k.contains('user-a')), isEmpty);
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
    final prefsA = await freshPrefs({'mem_plus_blob|user-a': noise});
    final payload = await BackupCollector(
      isarA,
      prefsA,
      const FixedRecordOwnerProvider('user-a'),
    ).collect(DateTime.utc(2026, 10, 17));
    final bytes = encodeBackup(payload);
    expect(bytes.length, greaterThan(64 * 1024));
    final decoded = decodeBackup(bytes);
    expect(decoded.error, isNull);
    expect(decoded.payload, payload);

    final isarB = await openIsar('big_b');
    final prefsB = await freshPrefs({});
    const ownerB = FixedRecordOwnerProvider('user-b');
    final result = await BackupRestorer(
      isarB,
      prefsB,
      ownerB,
      AccountDataReset(isarB, prefsB, owner: ownerB),
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
      ...ownerAPrefs,
      // Other owners.
      'mem_plus_kids_progress|user-b': '{}',
      'ramadan_card_dismissed_end_1447|user-b': true,
      'ramadan_tarawih|user-b': '[]',
      'kids_reading_receipts_user-b': '{}',
      'kids_support_profile_user-b': '{}',
      'kids_family_practice_user-b': '{}',
      'adult_journey_v1_user-b': '{}',
      'quran_bookmarks_owner_user-b': '[]',
      'quran_bookmarks_owner_user-ab': '[]',
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
    final payload = await BackupCollector(
      isar,
      prefs,
      const FixedRecordOwnerProvider('user-a'),
    ).collect(DateTime.utc(2026, 10, 17));

    expect(payload.sections.keys.toSet(), BackupSections.all);
    final prefsSection = payload.sections[BackupSections.prefs]! as Map;
    expect(prefsSection.keys.toSet(), {
      'read_pages',
      'user_profile',
      'khatmah_active_plan',
      'mem_plus_kids_progress|{owner}',
      'mem_plus_home_missions|{owner}',
      'ramadan_tarawih|{owner}',
      'ramadan_card_dismissed_start_1448|{owner}',
      'kids_reading_receipts_{owner}',
      'adult_journey_v1_{owner}',
      'quran_bookmarks_owner_{owner}',
      'quran_bookmarks_owner_{owner}_migrated',
      'daily_wird_target_2026-09-08',
      'hifz_pace',
      'mem_plus_track_list',
    });
    expect(prefsSection['mem_plus_kids_progress|{owner}'], {
      't': 's',
      'v': '{"stars":3}',
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
    final json = encodeBackup(payload);
    final text = String.fromCharCodes(gzip.decode(json));
    expect(text.contains('user-a'), isFalse);
    expect(text.contains('user-b'), isFalse);
  });

  Future<
    ({Isar isar, SharedPreferences prefs, BackupRestorer restorer, Map snap})
  >
  ownerBWithData(String tag) async {
    final isar = await openIsar(tag);
    await isar.writeTxn(() async {
      await isar.isarAyahReviewRecords.put(
        _review(
          key: 'user-b|adult|5|5',
          owner: 'user-b',
          audience: 'adult',
          surah: 5,
          ayah: 5,
        ),
      );
      await isar.xpIsars.put(XpIsar()..totalXp = 99);
    });
    final prefs = await freshPrefs({
      'read_pages': '[600]',
      'azkar_counter_morning_z1': 3,
      'ramadan_tarawih|user-b': '[{"night":9}]',
      'theme_mode': 'dark',
    });
    const owner = FixedRecordOwnerProvider('user-b');
    return (
      isar: isar,
      prefs: prefs,
      restorer: BackupRestorer(
        isar,
        prefs,
        owner,
        AccountDataReset(isar, prefs, owner: owner),
      ),
      snap: {for (final k in prefs.getKeys()) k: prefs.get(k)},
    );
  }

  Future<BackupPayload> ownerAPayload() async {
    final isarA = await openIsar('src');
    await seedOwnerA(isarA);
    final prefsA = await freshPrefs(ownerAPrefs);
    return BackupCollector(
      isarA,
      prefsA,
      const FixedRecordOwnerProvider('user-a'),
    ).collect(DateTime.utc(2026, 10, 17));
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
        'negative xp': mutate(good, (s) {
          (s[BackupSections.xp]! as Map)['totalXp'] = -1;
        }),
        'device key in prefs': mutate(good, (s) {
          (s[BackupSections.prefs]! as Map)['theme_mode'] = {
            't': 's',
            'v': 'light',
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
        final env = await ownerBWithData('inv_${entry.key.hashCode}');
        final result = await env.restorer.restore(entry.value);
        expect(result, BackupRestoreResult.invalidSections, reason: entry.key);
        final reviews = await env.isar.isarAyahReviewRecords.where().findAll();
        expect(reviews.map((r) => r.compositeKey), [
          'user-b|adult|5|5',
        ], reason: entry.key);
        expect((await env.isar.xpIsars.get(1))!.totalXp, 99);
        expect(
          {for (final k in env.prefs.getKeys()) k: env.prefs.get(k)},
          env.snap,
          reason: entry.key,
        );
      }
    },
  );

  test(
    'restore replaces: data present before restore that is not in the backup '
    'is gone',
    () async {
      final payload = await ownerAPayload();
      final env = await ownerBWithData('replace');
      final result = await env.restorer.restore(payload);
      expect(result, BackupRestoreResult.restored);

      final keys = (await env.isar.isarAyahReviewRecords.where().findAll())
          .map((r) => r.compositeKey)
          .toSet();
      expect(keys, isNot(contains('user-b|adult|5|5')));
      expect(keys, contains('user-b|adult|2|255'));
      expect((await env.isar.xpIsars.get(1))!.totalXp, 1234);
      expect(env.prefs.getString('read_pages'), '[1,2]');
      expect(env.prefs.containsKey('azkar_counter_morning_z1'), isFalse);
      expect(env.prefs.getString('ramadan_tarawih|user-b'), '[{"night":1}]');
      // Device settings survive a restore.
      expect(env.prefs.getString('theme_mode'), 'dark');
    },
  );

  test(
    'owner switch during restore: the owner is captured once at the start',
    () async {
      final payload = await ownerAPayload();
      final isar = await openIsar('switch');
      final prefs = await freshPrefs({});
      final owner = _SwitchingOwner('user-b', 'user-c');
      final result = await BackupRestorer(
        isar,
        prefs,
        owner,
        AccountDataReset(isar, prefs, owner: owner),
      ).restore(payload);
      expect(result, BackupRestoreResult.restored);
      expect(owner.reads, 1);

      final reviews = await isar.isarAyahReviewRecords.where().findAll();
      expect(reviews.every((r) => r.ownerUserId == 'user-b'), isTrue);
      expect(
        reviews.every((r) => r.compositeKey.startsWith('user-b|')),
        isTrue,
      );
      expect(prefs.getString('ramadan_tarawih|user-b'), '[{"night":1}]');
      expect(prefs.getString('khatmah_owner'), 'user-b');
      expect(prefs.getKeys().where((k) => k.contains('user-c')), isEmpty);
    },
  );
}
