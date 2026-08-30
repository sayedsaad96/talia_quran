import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/pending_bookmark_recovery_marker.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/core/security/encrypted_account_preferences_store.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/streak/data/models/daily_activity_isar.dart';
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';
import 'package:talia_quran/features/xp/data/models/xp_isar.dart';

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\'
          'isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
      if (File(dllPath).existsSync()) {
        await Isar.initializeIsarCore(libraries: {Abi.current(): dllPath});
        _isarCoreInitialized = true;
        return;
      }
    }
  }
  await Isar.initializeIsarCore();
  _isarCoreInitialized = true;
}

void main() {
  group('AccountDataReset', () {
    late Isar isar;
    late SharedPreferences prefs;
    late Directory dir;

    setUp(() async {
      await _initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({
        'user_profile': 'A',
        'read_pages': '[1,2]',
        'ayah_review_pull_cursor': '2026-08-01T00:00:00Z',
        'ayah_review_pull_cursor_pulled_at': '2026-08-01T00:00:00Z',
        'synced_certificate_ids': <String>['cert_juz_1'],
        'earned_certificates_v2': '[]',
        'earned_certificates_v2_kids': '[]',
        'has_new_certificate': true,
        'has_new_certificate_kids': true,
        'daily_plan_cloud_dirty': true,
        'custom_plan_cloud_dirty': true,
        'daily_plan_cloud_revision': 3,
        'custom_plan_cloud_revision': 2,
        'daily_plan_cloud_conflict': '{}',
        'custom_plan_cloud_conflict': '{}',
        'quran_bookmarks': '[{}]',
        'last_restorable_location': '/memorization-v2/session?surahId=67',
        'mem_plus_profile': '{}',
        'mem_plus_local_records_claimed_by': 'user-a',
        'mem_plus_review_identity_keys_v1': true,
        'hifz_path_mode': 'adult',
        'hifz_isar_migrated': true,
        'theme_mode': 'dark',
        'locale': 'ar',
        'bookmarks': '[]',
        'onboarding_user_type': 'adult',
        'unified_journey_enabled': true,
      });
      prefs = await SharedPreferences.getInstance();
      dir = await Directory.systemTemp.createTemp('talia_reset_');
      isar = await Isar.open(
        [
          IsarAyahProgressSchema,
          IsarAyahReviewRecordSchema,
          IsarV2SessionSchema,
          StreakIsarSchema,
          XpIsarSchema,
          DailyActivityIsarSchema,
          CloudSyncQueueItemSchema,
        ],
        directory: dir.path,
        name: 'reset_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
    });

    Future<void> seedAllCollections() async {
      await isar.writeTxn(() async {
        await isar.isarAyahReviewRecords.put(
          IsarAyahReviewRecord()
            ..compositeKey = 'user-a|adult|1|1'
            ..ownerUserId = 'user-a'
            ..audience = 'adult'
            ..surahId = 1
            ..ayahNumber = 1
            ..strengthLevel = 1
            ..intervalDays = 1
            ..lastReviewedAt = DateTime.utc(2026, 8, 8)
            ..nextReviewDate = DateTime.utc(2026, 8, 9)
            ..totalReviews = 1,
        );
        await isar.isarAyahProgress.put(
          IsarAyahProgress()
            ..compositeKey = '1_1'
            ..surahId = 1
            ..ayahNumber = 1
            ..status = AyahStatus.notStarted
            ..repetitions = 0
            ..nextReviewDate = DateTime.utc(2026, 8, 9)
            ..lastReviewDate = DateTime.utc(2026, 8, 8),
        );
        await isar.cloudSyncQueueItems.put(
          CloudSyncQueueItem()
            ..kind = 'production_push'
            ..ownerUserId = 'user-a'
            ..nextRetryAt = DateTime.utc(2026, 8, 8)
            ..createdAt = DateTime.utc(2026, 8, 8),
        );
      });
    }

    test('clears every account-owned Isar collection', () async {
      await seedAllCollections();
      await AccountDataReset(isar, prefs).clearAccountOwnedData();
      expect(await isar.isarAyahReviewRecords.where().count(), 0);
      expect(await isar.isarAyahProgress.where().count(), 0);
      expect(await isar.isarV2Sessions.where().count(), 0);
      expect(await isar.streakIsars.where().count(), 0);
      expect(await isar.xpIsars.where().count(), 0);
      expect(await isar.dailyActivityIsars.where().count(), 0);
      expect(await isar.cloudSyncQueueItems.where().count(), 0);
    });

    test('clears the sync cursor and certificate bookkeeping', () async {
      await AccountDataReset(isar, prefs).clearAccountOwnedData();
      expect(prefs.getString('ayah_review_pull_cursor'), isNull);
      expect(prefs.getString('ayah_review_pull_cursor_pulled_at'), isNull);
      expect(prefs.getStringList('synced_certificate_ids'), isNull);
      expect(prefs.getString('earned_certificates_v2'), isNull);
      expect(prefs.getString('earned_certificates_v2_kids'), isNull);
      expect(prefs.getBool('has_new_certificate'), isNull);
      expect(prefs.getBool('has_new_certificate_kids'), isNull);
      expect(prefs.getBool('daily_plan_cloud_dirty'), isNull);
      expect(prefs.getBool('custom_plan_cloud_dirty'), isNull);
      expect(prefs.getInt('daily_plan_cloud_revision'), isNull);
      expect(prefs.getInt('custom_plan_cloud_revision'), isNull);
      expect(prefs.getString('daily_plan_cloud_conflict'), isNull);
      expect(prefs.getString('custom_plan_cloud_conflict'), isNull);
      expect(prefs.getString('quran_bookmarks'), isNull);
      expect(prefs.getString('last_restorable_location'), isNull);
      expect(prefs.getString('mem_plus_local_records_claimed_by'), isNull);
    });

    test('clears prefixed memorization and hifz keys', () async {
      await AccountDataReset(isar, prefs).clearAccountOwnedData();
      expect(prefs.getString('mem_plus_profile'), isNull);
      expect(prefs.getBool('mem_plus_review_identity_keys_v1'), isNull);
      expect(prefs.getString('hifz_path_mode'), isNull);
      expect(prefs.getBool('hifz_isar_migrated'), isNull);
    });

    test('retains device preferences', () async {
      await AccountDataReset(isar, prefs).clearAccountOwnedData();
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getString('locale'), 'ar');
      expect(prefs.getString('bookmarks'), '[]');
      expect(prefs.getString('onboarding_user_type'), 'adult');
      expect(prefs.getBool('unified_journey_enabled'), isTrue);
    });

    test('the two inventories never overlap', () {
      for (final retained in AccountDataReset.retainedPreferenceKeys) {
        expect(
          AccountDataReset.clearedPreferenceKeys.contains(retained),
          isFalse,
          reason: '$retained is listed as both cleared and retained',
        );
        for (final prefix in AccountDataReset.clearedPreferencePrefixes) {
          expect(
            retained.startsWith(prefix),
            isFalse,
            reason: '$retained would be wiped by the "$prefix" prefix',
          );
        }
      }
    });

    test('is safe to run twice', () async {
      await seedAllCollections();
      final reset = AccountDataReset(isar, prefs);
      await reset.clearAccountOwnedData();
      await reset.clearAccountOwnedData();
      expect(await isar.isarAyahReviewRecords.where().count(), 0);
    });

    test(
      're-homes deleted-account progress as guest data without clearing it',
      () async {
        await seedAllCollections();

        await AccountDataReset(
          isar,
          prefs,
        ).preserveDeletedAccountLocally(departingOwnerId: 'user-a');

        final review = await isar.isarAyahReviewRecords.where().findFirst();
        expect(review, isNotNull);
        expect(review!.ownerUserId, ReviewRecordIdentity.localOwnerId);
        expect(review.compositeKey, 'local|adult|1|1');
        expect(review.cloudDirty, isFalse);
        expect(await isar.isarAyahProgress.where().count(), 1);
        expect(await isar.cloudSyncQueueItems.where().count(), 1);
        expect(prefs.getString('read_pages'), '[1,2]');
        expect(prefs.getString('auth_last_signed_in_user_id'), isNull);
      },
    );

    test(
      'failed deleted-account guest copy preserves owner blob and marker',
      () async {
        final encrypted = _GuestWriteFailingEncryptedStore();
        await encrypted.write('user-a', 'quran_bookmarks', '[{"revision":1}]');
        encrypted.failGuestWrite = true;

        await expectLater(
          AccountDataReset(
            isar,
            prefs,
            encryptedAccountPreferences: encrypted,
          ).preserveDeletedAccountLocally(departingOwnerId: 'user-a'),
          throwsException,
        );

        expect(
          await encrypted.read('user-a', 'quran_bookmarks'),
          '[{"revision":1}]',
        );
        expect(PendingBookmarkRecoveryMarker.contains(prefs, 'user-a'), isTrue);
      },
    );
  });
}

class _GuestWriteFailingEncryptedStore
    implements EncryptedAccountPreferencesStore {
  final Map<String, String> _values = {};
  bool failGuestWrite = false;

  @override
  Future<void> delete(String ownerId, String key) async {
    _values.remove('$ownerId/$key');
  }

  @override
  Future<String?> read(String ownerId, String key) async =>
      _values['$ownerId/$key'];

  @override
  Future<void> write(String ownerId, String key, String value) async {
    if (failGuestWrite && ownerId == ReviewRecordIdentity.localOwnerId) {
      throw Exception('guest secure write failed');
    }
    _values['$ownerId/$key'] = value;
  }
}
