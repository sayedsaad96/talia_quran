import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/quran/data/models/isar_ayah_note.dart';
import 'package:talia_quran/features/quran/data/repositories/isar_ayah_note_repository.dart';
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';

import '../../helpers/isar_test_core.dart';

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
  late DateTime now;

  setUpAll(initializeIsarCoreForTests);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = _Owner('owner-a');
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    now = DateTime.utc(2026, 10, 19, 8);
    directory = await Directory.systemTemp.createTemp('talia_ayah_notes_');
    isar = await Isar.open(
      appIsarSchemas,
      directory: directory.path,
      name: 'notes_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });

  IsarAyahNoteRepository repository() =>
      IsarAyahNoteRepository(isar, owner, barrier, clock: () => now);

  Future<void> switchOwner(String ownerId) async {
    barrier.prepareOwner(ownerId);
    owner.currentOwnerId = ownerId;
    await barrier.markOwnerReady(ownerId);
  }

  test(
    'scopes CRUD to owner, keeps createdAt, and retains one row per ayah',
    () async {
      final notes = repository();
      final first = await notes.upsert(1, 1, 'private A');
      now = now.add(const Duration(minutes: 5));
      final updated = await notes.upsert(1, 1, 'updated A');

      expect(updated.createdAt.toUtc(), first.createdAt.toUtc());
      expect(updated.updatedAt.toUtc(), now.toUtc());
      expect((await isar.isarAyahNotes.where().findAll()).length, 1);

      await switchOwner('owner-b');
      final otherOwner = repository();
      expect(await otherOwner.get(1, 1), isNull);
      await otherOwner.upsert(1, 1, 'private B');
      expect((await otherOwner.listAll()).single.body, 'private B');

      await switchOwner('owner-a');
      expect((await repository().get(1, 1))!.body, 'updated A');
      await repository().delete(1, 1);
      expect(await repository().get(1, 1), isNull);
      await switchOwner('owner-b');
      expect((await repository().get(1, 1))!.body, 'private B');
    },
  );

  test(
    'validates canonical references and the 1000-grapheme boundary',
    () async {
      final notes = repository();
      await notes.upsert(114, 6, List.filled(1000, 'a').join());
      await notes.upsert(1, 1, List.filled(1000, 'e\u{301}').join());
      await expectLater(
        notes.upsert(114, 6, List.filled(1001, 'a').join()),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        notes.upsert(1, 8, 'x'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        notes.upsert(115, 1, 'x'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        notes.upsert(1, 1, '   '),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        notes.upsert(1, 2, List.filled(1001, '👩🏽‍💻').join()),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'clock rollback cannot create a note rejected by backup validation',
    () async {
      final notes = repository();
      final first = await notes.upsert(1, 1, 'First body');
      now = now.subtract(const Duration(hours: 1));
      final updated = await notes.upsert(1, 1, 'Edited body');

      expect(updated.createdAt.toUtc(), first.createdAt.toUtc());
      expect(
        updated.updatedAt.isBefore(updated.createdAt),
        isFalse,
        reason: 'A locally edited note must remain backup-restorable.',
      );
    },
  );

  test(
    'generation invalidation rejects a queued write without resurrection',
    () async {
      final hold = Completer<void>();
      final active = expectLater(
        barrier.run((_) => hold.future),
        throwsA(isA<AccountDataUnavailableException>()),
      );
      final pending = expectLater(
        repository().upsert(2, 255, 'must not persist'),
        throwsA(isA<AccountDataUnavailableException>()),
      );

      final reset = AccountDataReset(
        isar,
        prefs,
        owner: owner,
      ).clearAccountOwnedData();
      hold.complete();

      await active;
      await reset;
      await pending;
      expect(await isar.isarAyahNotes.count(), 0);
    },
  );

  test('additive note schema reopens an existing database without data loss',
      () async {
    final legacyDirectory =
        await Directory.systemTemp.createTemp('talia_legacy_');
    const name = 'pre_notes';
    final legacySchemas = appIsarSchemas
        .where((schema) => schema.name != IsarAyahNoteSchema.name)
        .toList();
    final legacy = await Isar.open(
      legacySchemas,
      directory: legacyDirectory.path,
      name: name,
    );
    await legacy.writeTxn(() async {
      await legacy.isarAyahReviewRecords.put(
        IsarAyahReviewRecord()
          ..compositeKey = 'owner-a|adult|1|1'
          ..ownerUserId = 'owner-a'
          ..audience = 'adult'
          ..surahId = 1
          ..ayahNumber = 1
          ..strengthLevel = 2
          ..intervalDays = 1
          ..lastReviewedAt = now
          ..nextReviewDate = now
          ..totalReviews = 1,
      );
      await legacy.streakIsars.put(StreakIsar()..currentStreak = 7);
    });
    await legacy.close();

    final reopened = await Isar.open(
      appIsarSchemas,
      directory: legacyDirectory.path,
      name: name,
    );
    try {
      expect(
        (await reopened.isarAyahReviewRecords.where().findAll()).single
            .compositeKey,
        'owner-a|adult|1|1',
      );
      expect((await reopened.streakIsars.get(1))!.currentStreak, 7);
      final migratedNotes = IsarAyahNoteRepository(
        reopened,
        owner,
        barrier,
        clock: () => now,
      );
      await migratedNotes.upsert(1, 1, 'Local note');
      expect((await migratedNotes.get(1, 1))!.body, 'Local note');
    } finally {
      await reopened.close(deleteFromDisk: true);
      await legacyDirectory.delete(recursive: true);
    }
  });

  test(
    'reset preserves designated recovery owner and deletion erases exact owner',
    () async {
      await isar.writeTxn(() async {
        await isar.isarAyahNotes.putAll([
          IsarAyahNote()
            ..ownerId = 'owner-a'
            ..surahId = 1
            ..ayahNumber = 1
            ..body = 'A'
            ..createdAt = now
            ..updatedAt = now,
          IsarAyahNote()
            ..ownerId = 'owner-b'
            ..surahId = 1
            ..ayahNumber = 1
            ..body = 'B'
            ..createdAt = now
            ..updatedAt = now,
        ]);
      });
      await prefs.setBool('pending_bookmark_recovery_owner_owner-b', true);

      await AccountDataReset(
        isar,
        prefs,
        owner: owner,
        documentsDirectory: () async => directory,
      ).clearAccountOwnedData();
      expect(
        (await isar.isarAyahNotes.where().findAll()).map(
          (note) => note.ownerId,
        ),
        ['owner-b'],
      );

      await AccountDataReset(
        isar,
        prefs,
        owner: owner,
        documentsDirectory: () async => directory,
      ).eraseDeletedAccountLocally(departingOwnerId: 'owner-b');
      expect(await isar.isarAyahNotes.count(), 0);
    },
  );

  test('claims guest notes without overwriting a newer account note', () async {
    IsarAyahNote row(String ownerId, int ayah, String body, DateTime at) =>
        IsarAyahNote()
          ..ownerId = ownerId
          ..surahId = 1
          ..ayahNumber = ayah
          ..body = body
          ..createdAt = at
          ..updatedAt = at;
    final old = DateTime.utc(2026, 1, 1);
    final recent = DateTime.utc(2026, 6, 1);
    await isar.writeTxn(() async {
      await isar.isarAyahNotes.putAll([
        row('local', 1, 'guest only', old),
        row('local', 2, 'guest older', old),
        row('local', 3, 'guest newer', recent),
        row('owner-a', 2, 'account newer', recent),
        row('owner-a', 3, 'account older', old),
        row('owner-b', 4, 'other owner', old),
      ]);
    });

    expect(await repository().claimLocalNotes(), 2);

    final mine = {
      for (final n in await repository().listAll()) n.ayahNumber: n.body,
    };
    expect(mine, {1: 'guest only', 2: 'account newer', 3: 'guest newer'});
    final rows = await isar.isarAyahNotes.where().findAll();
    expect(rows.where((r) => r.ownerId == 'owner-b').single.body, 'other owner');
    expect(await repository().claimLocalNotes(), 0);
  });

  test('a guest owner claims nothing', () async {
    await switchOwner('local');
    expect(await repository().claimLocalNotes(), 0);
  });
}
