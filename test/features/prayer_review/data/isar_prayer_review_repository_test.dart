import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import 'package:talia_quran/features/prayer_review/data/models/isar_prayer_review_receipt.dart';
import 'package:talia_quran/features/prayer_review/data/repositories/isar_prayer_review_repository.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';

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
  late _Owner owner;
  late AccountDataBarrier barrier;
  late IsarPrayerReviewRepository repository;

  setUpAll(initializeIsarCoreForTests);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    owner = _Owner('owner-a');
    barrier = AccountDataBarrier.forPreferences(preferences)..owner = owner;
    directory = await Directory('.superpowers/tmp').createTemp('prayer_review_');
    isar = await Isar.open(
      [IsarPrayerReviewAssignmentSchema, IsarPrayerReviewReceiptSchema],
      directory: directory.path,
      name: 'review_${DateTime.now().microsecondsSinceEpoch}',
    );
    repository = IsarPrayerReviewRepository(isar, owner, barrier);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    final root = Directory('.superpowers/tmp').absolute.path;
    expect(directory.absolute.path.startsWith(root), isTrue);
    await directory.delete(recursive: true);
  });

  PrayerReviewSelection selection({
    PrayerKey prayer = PrayerKey.dhuhr,
    int startAyah = 1,
    int endAyah = 3,
  }) => PrayerReviewSelection(
    ownerId: owner.currentOwnerId,
    localDayKey: '2026-10-20',
    prayerKey: prayer,
    scheduledAt: DateTime.utc(2026, 10, 20, 12),
    selectedAt: DateTime.utc(2026, 10, 20, 11),
    surahId: 2,
    startAyah: startAyah,
    endAyah: endAyah,
  );

  PrayerReviewReceipt receipt({
    int gradeIndex = 0,
    PrayerKey prayer = PrayerKey.dhuhr,
  }) {
    final selected = selection(prayer: prayer);
    return PrayerReviewReceipt(
      ownerId: selected.ownerId,
      localDayKey: selected.localDayKey,
      surahId: selected.surahId,
      startAyah: selected.startAyah,
      endAyah: selected.endAyah,
      gradeIndex: gradeIndex,
      committedAt: DateTime.utc(2026, 10, 20, 12),
      eventIds: const ['event-1', 'event-2', 'event-3'],
    );
  }

  Future<PrayerReviewReceiptWriteResult> writeReceipt(
    PrayerReviewReceipt proposed,
  ) {
    final authority = repository.captureAuthority();
    return barrier.run(
      (lease) => isar.writeTxn(
        () => PrayerReviewReceiptTransactionWriter.record(
          isar,
          authority: authority,
          proposed: proposed,
        ),
      ),
      authority: authority.lease,
    );
  }

  test('first assignment freezes the occurrence despite later proposals', () async {
    final first = selection(startAyah: 1, endAyah: 3);
    final later = PrayerReviewSelection(
      ownerId: owner.currentOwnerId,
      localDayKey: first.localDayKey,
      prayerKey: first.prayerKey,
      scheduledAt: DateTime.utc(2026, 10, 20, 13),
      selectedAt: DateTime.utc(2026, 10, 20, 12),
      surahId: 2,
      startAyah: 4,
      endAyah: 6,
    );

    final authority = repository.captureAuthority();
    expect(await repository.saveAssignmentIfAbsent(first, authority), first);
    final stored = await repository.saveAssignmentIfAbsent(later, authority);

    expect(stored, first);
    expect(await isar.isarPrayerReviewAssignments.count(), 1);
  });

  test('concurrent assignment proposals have one deterministic winner', () async {
    final first = selection(startAyah: 1, endAyah: 3);
    final later = PrayerReviewSelection(
      ownerId: owner.currentOwnerId,
      localDayKey: first.localDayKey,
      prayerKey: first.prayerKey,
      scheduledAt: DateTime.utc(2026, 10, 20, 12),
      selectedAt: DateTime.utc(2026, 10, 20, 11),
      surahId: 2,
      startAyah: 4,
      endAyah: 6,
    );

    final results = await Future.wait([
      repository.saveAssignmentIfAbsent(first, repository.captureAuthority()),
      repository.saveAssignmentIfAbsent(later, repository.captureAuthority()),
    ]);

    expect(results.toSet().length, 1);
    expect(await isar.isarPrayerReviewAssignments.count(), 1);
  });

  test('owner isolation and invalidated leases reject writes', () async {
    final foreign = PrayerReviewSelection(
      ownerId: 'owner-b',
      localDayKey: '2026-10-20',
      prayerKey: PrayerKey.dhuhr,
      scheduledAt: DateTime.utc(2026, 10, 20, 12),
      selectedAt: DateTime.utc(2026, 10, 20, 11),
      surahId: 2,
      startAyah: 1,
      endAyah: 3,
    );
    await expectLater(
      repository.saveAssignmentIfAbsent(foreign, repository.captureAuthority()),
      throwsA(isA<AccountDataUnavailableException>()),
    );

    final authority = repository.captureAuthority();
    barrier.invalidate();
    await expectLater(
      barrier.run(
        (lease) => isar.writeTxn(
          () => PrayerReviewReceiptTransactionWriter.record(
            isar,
            authority: authority,
            proposed: receipt(),
          ),
        ),
        authority: authority.lease,
      ),
      throwsA(isA<AccountDataUnavailableException>()),
    );
    expect(await isar.isarPrayerReviewAssignments.count(), 0);
    expect(await isar.isarPrayerReviewReceipts.count(), 0);
  });

  test('transaction rollback does not retain a daily receipt', () async {
    final authority = repository.captureAuthority();
    await expectLater(
      barrier.run(
        (lease) => isar.writeTxn(() async {
          await PrayerReviewReceiptTransactionWriter.record(
            isar,
            authority: authority,
            proposed: receipt(),
          );
          throw StateError('simulate later SRS failure');
        }),
        authority: authority.lease,
      ),
      throwsStateError,
    );
    expect(await isar.isarPrayerReviewReceipts.count(), 0);
  });

  test('same exact passage is fenced across prayers and grade changes', () async {
    final first = await writeReceipt(receipt(gradeIndex: 0));
    final duplicate = await writeReceipt(
      receipt(gradeIndex: 2, prayer: PrayerKey.asr),
    );

    expect(first.alreadyCommitted, isFalse);
    expect(duplicate.alreadyCommitted, isTrue);
    expect(duplicate.receipt.gradeIndex, 0);
    expect(await isar.isarPrayerReviewReceipts.count(), 1);
  });

  test('rejects invalid canonical bounds, day keys, and grade indexes', () {
    expect(
      () => PrayerReviewSelection(
        ownerId: 'owner-a',
        localDayKey: '2026-02-30',
        prayerKey: PrayerKey.fajr,
        scheduledAt: DateTime.utc(2026),
        selectedAt: DateTime.utc(2026),
        surahId: 2,
        startAyah: 1,
        endAyah: 16,
      ),
      throwsFormatException,
    );
    expect(
      () => PrayerReviewReceipt(
        ownerId: 'owner-a',
        localDayKey: '2026-10-20T00:00:00',
        surahId: 1,
        startAyah: 1,
        endAyah: 1,
        gradeIndex: 3,
        committedAt: DateTime.utc(2026),
        eventIds: const ['event'],
      ),
      throwsFormatException,
    );
  });
}
