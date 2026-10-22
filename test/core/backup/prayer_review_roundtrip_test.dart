import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/backup/backup_collector.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';
import 'package:talia_quran/core/backup/backup_restorer.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import 'package:talia_quran/features/prayer_review/data/models/isar_prayer_review_receipt.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';

import '../../helpers/isar_test_core.dart';

class _RejectingPreferences extends InMemorySharedPreferencesStore {
  _RejectingPreferences() : super.withData({});

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key.endsWith('user_profile')) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  late Directory directory;
  late Isar source;
  late Isar target;
  late SharedPreferences prefs;
  final today = DateTime.now();
  final day =
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';

  Future<void> seed(Isar isar, String owner, String date, int grade) =>
      isar.writeTxn(() async {
        await isar.isarPrayerReviewReceipts.put(
          IsarPrayerReviewReceipt()
            ..ownerId = owner
            ..audience = 'adult'
            ..receiptKey = PrayerReviewIdentity.receiptKey(
              ownerId: owner,
              localDayKey: date,
              surahId: 1,
              startAyah: 1,
              endAyah: 1,
            )
            ..localDayKey = date
            ..surahId = 1
            ..startAyah = 1
            ..endAyah = 1
            ..gradeIndex = grade
            ..committedAt = DateTime.utc(2026, 1, 1)
            ..eventIds = ['event-$grade'],
        );
      });

  Future<BackupPayload> collect() => BackupCollector(
    source,
    prefs,
    const FixedRecordOwnerProvider('source-owner'),
  ).collect(DateTime.utc(2026, 10, 20));

  Future<BackupRestoreResult> restore(BackupPayload payload) => BackupRestorer(
    target,
    prefs,
    const FixedRecordOwnerProvider('target-owner'),
  ).restore(payload);

  setUpAll(initializeIsarCoreForTests);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    directory = await Directory(
      '.superpowers/tmp',
    ).createTemp('prayer_backup_');
    final suffix = DateTime.now().microsecondsSinceEpoch;
    source = await Isar.open(
      appIsarSchemas,
      directory: directory.path,
      name: 'prayer_source_$suffix',
    );
    target = await Isar.open(
      appIsarSchemas,
      directory: directory.path,
      name: 'prayer_target_$suffix',
    );
  });
  tearDown(() async {
    await source.close(deleteFromDisk: true);
    await target.close(deleteFromDisk: true);
    expect(
      directory.absolute.path.startsWith(
        Directory('.superpowers/tmp').absolute.path,
      ),
      isTrue,
    );
    await directory.delete(recursive: true);
  });

  test('v4 exports prayer sections and rebinds receipt identity', () async {
    await seed(source, 'source-owner', '2026-01-01', 1);
    final payload = await collect();
    expect(payload.schemaVersion, 4);
    expect(payload.sections, contains('prayerReviewAssignments'));
    expect(payload.sections, contains('prayerReviewReceipts'));
    expect(await restore(payload), BackupRestoreResult.restored);
    final row =
        (await target.isarPrayerReviewReceipts.where().findAll()).single;
    expect(row.ownerId, 'target-owner');
    expect(
      row.receiptKey,
      PrayerReviewIdentity.receiptKey(
        ownerId: 'target-owner',
        localDayKey: '2026-01-01',
        surahId: 1,
        startAyah: 1,
        endAyah: 1,
      ),
    );
    expect(row.eventIds, ['event-1']);
  });

  test(
    'assignment roundtrip preserves frozen range and prompt consumption',
    () async {
      final selection = PrayerReviewSelection(
        ownerId: 'source-owner',
        localDayKey: '2026-01-01',
        prayerKey: PrayerKey.dhuhr,
        scheduledAt: DateTime.utc(2026, 1, 1, 12),
        selectedAt: DateTime.utc(2026, 1, 1, 11),
        surahId: 2,
        startAyah: 1,
        endAyah: 15,
        promptConsumed: true,
      );
      await source.writeTxn(() async {
        await source.isarPrayerReviewAssignments.put(
          IsarPrayerReviewAssignment()
            ..ownerId = selection.ownerId
            ..audience = 'adult'
            ..occurrenceKey = selection.occurrenceKey
            ..localDayKey = selection.localDayKey
            ..prayerKeyIndex = selection.prayerKey.index
            ..scheduledAt = selection.scheduledAt
            ..selectedAt = selection.selectedAt
            ..surahId = 2
            ..startAyah = 1
            ..endAyah = 15
            ..selectionVersion = 1
            ..promptConsumed = true,
        );
      });
      expect(await restore(await collect()), BackupRestoreResult.restored);
      final row =
          (await target.isarPrayerReviewAssignments.where().findAll()).single;
      expect(row.ownerId, 'target-owner');
      expect(row.endAyah, 15);
      expect(row.promptConsumed, isTrue);
      expect(
        row.occurrenceKey,
        PrayerReviewIdentity.occurrenceKey(
          ownerId: 'target-owner',
          localDayKey: selection.localDayKey,
          prayerKey: selection.prayerKey,
        ),
      );
    },
  );

  test('preference failure restores exact device receipt history', () async {
    await seed(source, 'source-owner', '2020-01-01', 0);
    await seed(target, 'target-owner', '2020-02-01', 2);
    await seed(target, 'target-owner', day, 1);
    await prefs.setString('user_profile', '{"name":"source"}');
    final payload = await collect();
    SharedPreferencesStorePlatform.instance = _RejectingPreferences();
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
    expect(await restore(payload), BackupRestoreResult.writeFailed);
    final rows = await target.isarPrayerReviewReceipts.where().findAll();
    expect(rows, hasLength(2));
    expect(rows.singleWhere((r) => r.localDayKey == day).gradeIndex, 1);
    expect(
      rows.singleWhere((r) => r.localDayKey == '2020-02-01').gradeIndex,
      2,
    );
    expect(rows.any((r) => r.localDayKey == '2020-01-01'), isFalse);
  });

  test('current-day device receipt wins repeated restore conflicts', () async {
    await seed(source, 'source-owner', day, 0);
    await seed(target, 'target-owner', day, 2);
    await seed(target, 'other-owner', day, 1);
    final payload = await collect();
    expect(await restore(payload), BackupRestoreResult.restored);
    expect(await restore(payload), BackupRestoreResult.restored);
    final rows = await target.isarPrayerReviewReceipts.where().findAll();
    expect(rows, hasLength(2));
    expect(rows.singleWhere((r) => r.ownerId == 'target-owner').gradeIndex, 2);
    expect(rows.singleWhere((r) => r.ownerId == 'other-owner').gradeIndex, 1);
  });

  for (final version in [1, 2, 3]) {
    test('v$version restore (no prayer sections) keeps every device receipt',
        () async {
      await seed(target, 'target-owner', day, 2);
      await seed(target, 'target-owner', '2020-01-01', 1);
      final current = await collect();
      final legacy = BackupPayload(
        schemaVersion: version,
        createdAt: current.createdAt,
        sections: {
          for (final key in BackupSections.forVersion(version))
            key: current.sections[key],
        },
      );
      expect(await restore(legacy), BackupRestoreResult.restored);
      final rows = await target.isarPrayerReviewReceipts.where().findAll();
      expect(rows, hasLength(2));
      expect(rows.singleWhere((r) => r.localDayKey == day).gradeIndex, 2);
      expect(
        rows.singleWhere((r) => r.localDayKey == '2020-01-01').gradeIndex,
        1,
      );
    });
  }

  test(
    'corrupt local receipt fails export instead of laundering identity',
    () async {
      await seed(source, 'source-owner', day, 1);
      await source.writeTxn(() async {
        final row =
            (await source.isarPrayerReviewReceipts.where().findAll()).single;
        row.receiptKey = 'invalid';
        await source.isarPrayerReviewReceipts.put(row);
      });
      await expectLater(collect(), throwsStateError);
    },
  );

  test(
    'malformed v4 receipt rejects before replacing any local rows',
    () async {
      await seed(source, 'source-owner', day, 0);
      await seed(target, 'target-owner', '2020-01-01', 2);
      final current = await collect();
      final malformed = BackupPayload(
        schemaVersion: 4,
        createdAt: current.createdAt,
        sections: {
          ...current.sections,
          'prayerReviewReceipts': [
            {'ownerId': kBackupOwnerToken, 'speech': 'forbidden'},
          ],
        },
      );
      expect(await restore(malformed), BackupRestoreResult.invalidSections);
      final row =
          (await target.isarPrayerReviewReceipts.where().findAll()).single;
      expect(row.localDayKey, '2020-01-01');
      expect(row.gradeIndex, 2);
      expect(await target.isarPrayerReviewAssignments.count(), 0);
    },
  );
}
