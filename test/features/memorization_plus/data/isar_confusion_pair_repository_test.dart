import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_confusion_pair.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/isar_confusion_pair_repository.dart';
import 'package:talia_quran/features/quran/data/models/isar_ayah_note.dart';

import '../../../helpers/isar_test_core.dart';

class _Owner implements RecordOwnerProvider {
  _Owner(this.currentOwnerId);
  @override
  String currentOwnerId;
  @override
  bool get isSignedIn => true;
}

void main() {
  late Directory directory;
  late Isar isar;
  late SharedPreferences prefs;
  late _Owner owner;
  late AccountDataBarrier barrier;

  setUpAll(initializeIsarCoreForTests);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = _Owner('owner-a');
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    directory = await Directory(
      '.superpowers/tmp',
    ).createTemp('confusion_pairs_');
    isar = await Isar.open(
      appIsarSchemas,
      directory: directory.path,
      name: 'pairs_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    final root = Directory('.superpowers/tmp').absolute.path;
    expect(directory.absolute.path.startsWith(root), isTrue);
    await directory.delete(recursive: true);
  });

  Future<void> record(DateTime at) async {
    final lease = barrier.capture();
    await isar.writeTxn(
      () => ConfusionPairTransactionWriter.record(
        isar,
        ownerId: owner.currentOwnerId,
        lease: lease,
        targetSurahId: 2,
        targetAyahNumber: 255,
        otherSurahId: 3,
        otherAyahNumber: 2,
        occurredAt: at,
      ),
    );
  }

  test(
    'increments an aggregate with UTC min/max dates across clock rollback',
    () async {
      await record(DateTime.utc(2026, 10, 20, 12));
      await record(DateTime.utc(2026, 10, 19, 12));

      final row = (await isar.isarConfusionPairs.where().findAll()).single;
      expect(row.count, 2);
      expect(row.firstAt.toUtc(), DateTime.utc(2026, 10, 19, 12));
      expect(row.lastAt.toUtc(), DateTime.utc(2026, 10, 20, 12));
    },
  );

  test('a lease for one owner cannot authorize another owner write', () async {
    final lease = barrier.capture();
    await expectLater(
      isar.writeTxn(
        () => ConfusionPairTransactionWriter.record(
          isar,
          ownerId: 'owner-b',
          lease: lease,
          targetSurahId: 2,
          targetAyahNumber: 255,
          otherSurahId: 3,
          otherAyahNumber: 2,
          occurredAt: DateTime.utc(2026),
        ),
      ),
      throwsA(isA<AccountDataUnavailableException>()),
    );
    expect(await isar.isarConfusionPairs.count(), 0);
  });

  test('an unbound lease cannot gain owner authority after capture', () async {
    barrier.owner = null;
    final lease = barrier.capture();
    barrier.owner = owner;
    await expectLater(
      isar.writeTxn(
        () => ConfusionPairTransactionWriter.record(
          isar,
          ownerId: owner.currentOwnerId,
          lease: lease,
          targetSurahId: 2,
          targetAyahNumber: 255,
          otherSurahId: 3,
          otherAyahNumber: 2,
          occurredAt: DateTime.utc(2026),
        ),
      ),
      throwsA(isA<AccountDataUnavailableException>()),
    );
    expect(await isar.isarConfusionPairs.count(), 0);
  });

  test('transaction rollback leaves no partial aggregate', () async {
    final lease = barrier.capture();
    await expectLater(
      isar.writeTxn(() async {
        await ConfusionPairTransactionWriter.record(
          isar,
          ownerId: owner.currentOwnerId,
          lease: lease,
          targetSurahId: 2,
          targetAyahNumber: 255,
          otherSurahId: 3,
          otherAyahNumber: 2,
          occurredAt: DateTime.utc(2026),
        );
        throw StateError('simulate failure after aggregate');
      }),
      throwsStateError,
    );
    expect(await isar.isarConfusionPairs.count(), 0);
  });

  test('captured lease invalidation rejects the write', () async {
    final lease = barrier.capture();
    barrier.invalidate();
    await expectLater(
      isar.writeTxn(
        () => ConfusionPairTransactionWriter.record(
          isar,
          ownerId: owner.currentOwnerId,
          lease: lease,
          targetSurahId: 2,
          targetAyahNumber: 255,
          otherSurahId: 3,
          otherAyahNumber: 2,
          occurredAt: DateTime.utc(2026),
        ),
      ),
      throwsA(isA<AccountDataUnavailableException>()),
    );
    expect(await isar.isarConfusionPairs.count(), 0);
  });

  test(
    'writer rejects an existing corrupt aggregate instead of healing it',
    () async {
      await isar.writeTxn(() async {
        await isar.isarConfusionPairs.put(
          IsarConfusionPair()
            ..ownerId = 'owner-a'
            ..audience = IsarConfusionPair.adultAudience
            ..targetKey = '2:255'
            ..otherKey = '3:2'
            ..count = 0
            ..firstAt = DateTime.utc(2026, 2)
            ..lastAt = DateTime.utc(2026, 1),
        );
      });
      final lease = barrier.capture();

      await expectLater(
        isar.writeTxn(
          () => ConfusionPairTransactionWriter.record(
            isar,
            ownerId: 'owner-a',
            lease: lease,
            targetSurahId: 2,
            targetAyahNumber: 255,
            otherSurahId: 3,
            otherAyahNumber: 2,
            occurredAt: DateTime.utc(2026),
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      expect((await isar.isarConfusionPairs.where().findAll()).single.count, 0);
    },
  );

  test('list skips a persisted noncanonical key alias and keeps the rest',
      () async {
    await record(DateTime.utc(2026));
    await isar.writeTxn(() async {
      await isar.isarConfusionPairs.put(
        IsarConfusionPair()
          ..ownerId = 'owner-a'
          ..audience = IsarConfusionPair.adultAudience
          ..targetKey = '02:255'
          ..otherKey = '3:2'
          ..count = 1
          ..firstAt = DateTime.utc(2026)
          ..lastAt = DateTime.utc(2026),
      );
    });
    final pairs = await IsarConfusionPairRepository(isar, owner, barrier).list();
    expect(pairs, hasLength(1));
    expect(pairs.single.targetSurahId, 2);
    expect(pairs.single.targetAyahNumber, 255);
  });

  test('list and reset stay owner-scoped', () async {
    await record(DateTime.utc(2026));
    await isar.writeTxn(() async {
      await isar.isarConfusionPairs.put(
        IsarConfusionPair()
          ..ownerId = 'owner-b'
          ..audience = IsarConfusionPair.adultAudience
          ..targetKey = '1:1'
          ..otherKey = '1:2'
          ..count = 3
          ..firstAt = DateTime.utc(2026)
          ..lastAt = DateTime.utc(2026),
      );
      await isar.isarAyahNotes.put(
        IsarAyahNote()
          ..ownerId = 'owner-a'
          ..surahId = 1
          ..ayahNumber = 1
          ..body = 'private'
          ..createdAt = DateTime.utc(2026)
          ..updatedAt = DateTime.utc(2026),
      );
    });
    expect(
      (await IsarConfusionPairRepository(
        isar,
        owner,
        barrier,
      ).list()).single.count,
      1,
    );

    await AccountDataReset(
      isar,
      prefs,
      owner: owner,
      documentsDirectory: () async => directory,
    ).eraseDeletedAccountLocally(departingOwnerId: 'owner-a');
    final remaining = await isar.isarConfusionPairs.where().findAll();
    expect(remaining.single.ownerId, 'owner-b');
    expect(await isar.isarAyahNotes.count(), 0);
  });

  test(
    'additive pair schema preserves existing notes and review rows',
    () async {
      final legacyDirectory = await Directory(
        '.superpowers/tmp',
      ).createTemp('pair_schema_upgrade_');
      const name = 'before_pairs';
      final oldSchemas = appIsarSchemas
          .where((schema) => schema.name != IsarConfusionPairSchema.name)
          .toList();
      final legacy = await Isar.open(
        oldSchemas,
        directory: legacyDirectory.path,
        name: name,
      );
      await legacy.writeTxn(() async {
        await legacy.isarAyahReviewRecords.put(
          IsarAyahReviewRecord()
            ..compositeKey = 'owner-a|adult|2|255'
            ..ownerUserId = 'owner-a'
            ..audience = 'adult'
            ..surahId = 2
            ..ayahNumber = 255
            ..strengthLevel = 2
            ..intervalDays = 1
            ..lastReviewedAt = DateTime.utc(2026)
            ..nextReviewDate = DateTime.utc(2026)
            ..totalReviews = 1,
        );
        await legacy.isarAyahNotes.put(
          IsarAyahNote()
            ..ownerId = 'owner-a'
            ..surahId = 1
            ..ayahNumber = 1
            ..body = 'D2 private note'
            ..createdAt = DateTime.utc(2026)
            ..updatedAt = DateTime.utc(2026),
        );
      });
      await legacy.close();
      final reopened = await Isar.open(
        appIsarSchemas,
        directory: legacyDirectory.path,
        name: name,
      );
      try {
        expect(
          (await reopened.isarAyahReviewRecords.where().findAll())
              .single
              .compositeKey,
          'owner-a|adult|2|255',
        );
        expect(
          (await reopened.isarAyahNotes.where().findAll()).single.body,
          'D2 private note',
        );
        final lease = barrier.capture();
        await reopened.writeTxn(
          () => ConfusionPairTransactionWriter.record(
            reopened,
            ownerId: 'owner-a',
            lease: lease,
            targetSurahId: 2,
            targetAyahNumber: 255,
            otherSurahId: 3,
            otherAyahNumber: 2,
            occurredAt: DateTime.utc(2026),
          ),
        );
        expect(await reopened.isarConfusionPairs.count(), 1);
      } finally {
        await reopened.close(deleteFromDisk: true);
        final root = Directory('.superpowers/tmp').absolute.path;
        expect(legacyDirectory.absolute.path.startsWith(root), isTrue);
        await legacyDirectory.delete(recursive: true);
      }
    },
  );
}
