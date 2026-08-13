import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
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

AyahReviewRecordModel _record({
  required int surahId,
  required int ayahNumber,
  required ReviewRecordCreatedByMode mode,
  int strengthLevel = 3,
}) {
  final now = DateTime.utc(2026, 8, 8);
  return AyahReviewRecordModel(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 1,
    lastReviewedAt: now,
    nextReviewDate: now.add(const Duration(days: 1)),
    totalReviews: 1,
    lastRating: PerformanceRating.average,
    createdByMode: mode,
  );
}

void main() {
  group('IS-2 account switch isolation', () {
    late Isar isar;
    late SharedPreferences prefs;
    late Directory dir;

    MemorizationPlusLocalDatasourceImpl datasourceFor(String ownerId) =>
        MemorizationPlusLocalDatasourceImpl(
          prefs,
          isar: isar,
          owner: FixedRecordOwnerProvider(ownerId),
        );

    setUp(() async {
      await _initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({
        'mem_plus_reviews_migrated_to_isar_v1': true,
        'mem_plus_review_identity_keys_v1': true,
      });
      prefs = await SharedPreferences.getInstance();
      dir = await Directory.systemTemp.createTemp('talia_is2_');
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
        name: 'is2_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
    });

    test('switching accounts leaves the arriving account with nothing',
        () async {
      await datasourceFor('user-a').saveReviewRecord(
        _record(
          surahId: 67,
          ayahNumber: 3,
          mode: ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 6,
        ),
      );
      await CloudSyncQueue(
        isar,
        const FixedRecordOwnerProvider('user-a'),
      ).enqueue(CloudSyncQueueKind.productionPush);
      await prefs.setString('ayah_review_pull_cursor', '2026-08-01T00:00:00Z');
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');

      final switched = await AuthCubit.resolveOwnerChange(
        prefs: prefs,
        userId: 'user-b',
        onDepartingAccount:
            AccountDataReset(isar, prefs).clearAccountOwnedData,
      );

      expect(switched, isTrue);
      expect(await datasourceFor('user-b').getAllReviewRecords(), isEmpty);
      expect(await isar.isarAyahReviewRecords.where().count(), 0);
      expect(await isar.cloudSyncQueueItems.where().count(), 0);
      expect(prefs.getString('ayah_review_pull_cursor'), isNull);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'user-b');
    });

    test('the arriving account starts from a clean pull cursor', () async {
      await prefs.setString('ayah_review_pull_cursor', '2026-08-01T00:00:00Z');
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');

      await AuthCubit.resolveOwnerChange(
        prefs: prefs,
        userId: 'user-b',
        onDepartingAccount:
            AccountDataReset(isar, prefs).clearAccountOwnedData,
      );

      expect(prefs.getString('ayah_review_pull_cursor'), isNull);
      expect(prefs.getString('ayah_review_pull_cursor_pulled_at'), isNull);
    });
  });
}
