import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

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
  int totalReviews = 2,
}) {
  final now = DateTime.utc(2026, 8, 8);
  return AyahReviewRecordModel(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 7,
    lastReviewedAt: now,
    nextReviewDate: now.add(const Duration(days: 7)),
    totalReviews: totalReviews,
    lastRating: PerformanceRating.average,
    createdByMode: mode,
  );
}

void main() {
  group('identity-scoped review record storage', () {
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
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dir = await Directory.systemTemp.createTemp('talia_identity_');
      isar = await Isar.open(
        [IsarAyahReviewRecordSchema],
        directory: dir.path,
        name: 'identity_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
    });

    test('write stores the four-part identity key, owner and audience',
        () async {
      final datasource = datasourceFor('user-a');
      await datasource.saveReviewRecord(
        _record(
          surahId: 67,
          ayahNumber: 3,
          mode: ReviewRecordCreatedByMode.v2Session,
        ),
      );

      final rows = await isar.isarAyahReviewRecords.where().findAll();
      expect(rows, hasLength(1));
      expect(rows.single.compositeKey, 'user-a|adult|67|3');
      expect(rows.single.ownerUserId, 'user-a');
      expect(rows.single.audience, 'adult');
    });

    test('adult and kids records on one ayah coexist for one owner', () async {
      final datasource = datasourceFor('user-a');
      await datasource.saveReviewRecord(
        _record(
          surahId: 67,
          ayahNumber: 3,
          mode: ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 6,
          totalReviews: 9,
        ),
      );
      await datasource.saveReviewRecord(
        _record(
          surahId: 67,
          ayahNumber: 3,
          mode: ReviewRecordCreatedByMode.kidsMode,
          strengthLevel: 1,
          totalReviews: 1,
        ),
      );

      final adult = await datasource.getReviewRecord(
        67,
        3,
        scope: ReviewRecordReadScope.adult,
      );
      final kids = await datasource.getReviewRecord(
        67,
        3,
        scope: ReviewRecordReadScope.kids,
      );

      expect(adult!.strengthLevel, 6);
      expect(adult.totalReviews, 9);
      expect(kids!.strengthLevel, 1);
      expect(kids.totalReviews, 1);
    });

    test('two owners on one ayah and audience do not collide', () async {
      await datasourceFor('user-a').saveReviewRecord(
        _record(
          surahId: 2,
          ayahNumber: 255,
          mode: ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 6,
        ),
      );
      await datasourceFor('user-b').saveReviewRecord(
        _record(
          surahId: 2,
          ayahNumber: 255,
          mode: ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 1,
        ),
      );

      final a = await datasourceFor('user-a').getReviewRecord(2, 255);
      final b = await datasourceFor('user-b').getReviewRecord(2, 255);
      expect(a!.strengthLevel, 6);
      expect(b!.strengthLevel, 1);
      expect(await isar.isarAyahReviewRecords.where().count(), 2);
    });

    test('getAllReviewRecords returns only the active owner and audience',
        () async {
      await datasourceFor('user-a').saveReviewRecord(
        _record(
          surahId: 1,
          ayahNumber: 1,
          mode: ReviewRecordCreatedByMode.v2Session,
        ),
      );
      await datasourceFor('user-a').saveReviewRecord(
        _record(
          surahId: 1,
          ayahNumber: 2,
          mode: ReviewRecordCreatedByMode.kidsMode,
        ),
      );
      await datasourceFor('user-b').saveReviewRecord(
        _record(
          surahId: 1,
          ayahNumber: 3,
          mode: ReviewRecordCreatedByMode.v2Session,
        ),
      );

      final adultA = await datasourceFor('user-a').getAllReviewRecords();
      expect(adultA.map((r) => r.ayahNumber), [1]);

      final kidsA = await datasourceFor(
        'user-a',
      ).getAllReviewRecords(scope: ReviewRecordReadScope.kids);
      expect(kidsA.map((r) => r.ayahNumber), [2]);

      final allA = await datasourceFor(
        'user-a',
      ).getAllReviewRecords(includeAllAudiences: true);
      expect(allA.map((r) => r.ayahNumber).toSet(), {1, 2});
    });

    test('includeAllAudiences never crosses the owner boundary', () async {
      await datasourceFor('user-b').saveReviewRecord(
        _record(
          surahId: 5,
          ayahNumber: 5,
          mode: ReviewRecordCreatedByMode.v2Session,
        ),
      );
      final dirtyForA = await datasourceFor(
        'user-a',
      ).getCloudDirtyReviewRecords(includeAllAudiences: true);
      expect(dirtyForA, isEmpty);
    });

    test('markReviewRecordsCloudSynced accepts identity keys', () async {
      final datasource = datasourceFor('user-a');
      await datasource.saveReviewRecord(
        _record(
          surahId: 9,
          ayahNumber: 9,
          mode: ReviewRecordCreatedByMode.v2Session,
        ),
      );
      expect(await datasource.getCloudDirtyReviewRecords(), hasLength(1));

      const identity = ReviewRecordIdentity(
        ownerUserId: 'user-a',
        audience: ReviewRecordReadScope.adult,
        surahId: 9,
        ayahNumber: 9,
      );
      await datasource.markReviewRecordsCloudSynced([identity.storageKey]);
      expect(await datasource.getCloudDirtyReviewRecords(), isEmpty);
    });
  });

  group('identity migration', () {
    late Isar isar;
    late SharedPreferences prefs;
    late Directory dir;

    MemorizationPlusLocalDatasourceImpl datasourceFor(String ownerId) =>
        MemorizationPlusLocalDatasourceImpl(
          prefs,
          isar: isar,
          owner: FixedRecordOwnerProvider(ownerId),
        );

    Future<void> seedRow(String compositeKey, ReviewRecordCreatedByMode mode) {
      final row = IsarAyahReviewRecord.fromModel(
        _record(surahId: 67, ayahNumber: 3, mode: mode),
      )..compositeKey = compositeKey;
      return isar.writeTxn(() => isar.isarAyahReviewRecords.put(row));
    }

    setUp(() async {
      await _initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({
        'mem_plus_reviews_migrated_to_isar_v1': true,
      });
      prefs = await SharedPreferences.getInstance();
      dir = await Directory.systemTemp.createTemp('talia_identity_mig_');
      isar = await Isar.open(
        [IsarAyahReviewRecordSchema],
        directory: dir.path,
        name: 'identity_mig_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
    });

    test('legacy key is re-keyed with audience from createdByMode', () async {
      await seedRow('67_3', ReviewRecordCreatedByMode.v2Session);

      final datasource = datasourceFor('user-a');
      await datasource.migrateReviewRecordIdentityIfNeeded();

      final rows = await isar.isarAyahReviewRecords.where().findAll();
      expect(rows, hasLength(1));
      expect(rows.single.compositeKey, 'user-a|adult|67|3');
      expect(rows.single.ownerUserId, 'user-a');
      expect(rows.single.audience, 'adult');
    });

    test('audience-scoped kids key keeps its audience', () async {
      await seedRow('kids_67_3', ReviewRecordCreatedByMode.kidsMode);

      await datasourceFor('user-a').migrateReviewRecordIdentityIfNeeded();

      final rows = await isar.isarAyahReviewRecords.where().findAll();
      expect(rows.single.compositeKey, 'user-a|kids|67|3');
      expect(rows.single.audience, 'kids');
    });

    test('signed-out migration assigns the reserved local owner', () async {
      await seedRow('67_3', ReviewRecordCreatedByMode.v2Session);

      await datasourceFor(
        ReviewRecordIdentity.localOwnerId,
      ).migrateReviewRecordIdentityIfNeeded();

      final rows = await isar.isarAyahReviewRecords.where().findAll();
      expect(rows.single.compositeKey, 'local|adult|67|3');
      expect(rows.single.cloudDirty, isFalse);
    });

    test('migration is idempotent and does not duplicate rows', () async {
      await seedRow('67_3', ReviewRecordCreatedByMode.v2Session);

      final datasource = datasourceFor('user-a');
      await datasource.migrateReviewRecordIdentityIfNeeded();
      await datasource.migrateReviewRecordIdentityIfNeeded();

      expect(await isar.isarAyahReviewRecords.where().count(), 1);
      expect(prefs.getBool('mem_plus_review_identity_keys_v1'), isTrue);
    });

    test('an existing identity row is never overwritten by a legacy row',
        () async {
      final existing = IsarAyahReviewRecord.fromModel(
        _record(
          surahId: 67,
          ayahNumber: 3,
          mode: ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 6,
          totalReviews: 20,
        ),
      )
        ..compositeKey = 'user-a|adult|67|3'
        ..ownerUserId = 'user-a'
        ..audience = 'adult';
      await isar.writeTxn(() => isar.isarAyahReviewRecords.put(existing));
      await seedRow('67_3', ReviewRecordCreatedByMode.v2Session);

      await datasourceFor('user-a').migrateReviewRecordIdentityIfNeeded();

      final row = await isar.isarAyahReviewRecords.getByCompositeKey(
        'user-a|adult|67|3',
      );
      expect(row!.strengthLevel, 6);
      expect(row.totalReviews, 20);
    });
  });

  group('guest-to-account claim', () {
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
      dir = await Directory.systemTemp.createTemp('talia_claim_');
      isar = await Isar.open(
        [IsarAyahReviewRecordSchema],
        directory: dir.path,
        name: 'claim_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
    });

    Future<void> seedLocalGuestRecord({int ayahNumber = 3}) async {
      await datasourceFor(
        ReviewRecordIdentity.localOwnerId,
      ).saveReviewRecord(
        _record(
          surahId: 67,
          ayahNumber: ayahNumber,
          mode: ReviewRecordCreatedByMode.v2Session,
          strengthLevel: 6,
          totalReviews: 12,
        ),
      );
    }

    test('first sign-in claims local records and marks them dirty', () async {
      await seedLocalGuestRecord();

      final claimed = await datasourceFor('user-a').claimLocalReviewRecords();
      expect(claimed, 1);

      final record = await datasourceFor('user-a').getReviewRecord(67, 3);
      expect(record, isNotNull);
      expect(record!.strengthLevel, 6);

      final row = await isar.isarAyahReviewRecords.getByCompositeKey(
        'user-a|adult|67|3',
      );
      expect(row!.cloudDirty, isTrue);
      expect(prefs.getString('mem_plus_local_records_claimed_by'), 'user-a');
    });

    test('a second account cannot claim already-claimed records', () async {
      await seedLocalGuestRecord();
      await datasourceFor('user-a').claimLocalReviewRecords();

      final claimedByB = await datasourceFor('user-b').claimLocalReviewRecords();
      expect(claimedByB, 0);
      expect(await datasourceFor('user-b').getReviewRecord(67, 3), isNull);
    });

    test('claim is skipped when the account already owns records', () async {
      await seedLocalGuestRecord();
      await datasourceFor('user-a').saveReviewRecord(
        _record(
          surahId: 1,
          ayahNumber: 1,
          mode: ReviewRecordCreatedByMode.v2Session,
        ),
      );

      final claimed = await datasourceFor('user-a').claimLocalReviewRecords();
      expect(claimed, 0);
      expect(prefs.getString('mem_plus_local_records_claimed_by'), isNull);
    });

    test('claim is a no-op when there is nothing owned by local', () async {
      final claimed = await datasourceFor('user-a').claimLocalReviewRecords();
      expect(claimed, 0);
    });
  });
}
