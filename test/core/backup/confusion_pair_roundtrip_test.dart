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
import 'package:talia_quran/features/memorization_plus/data/models/isar_confusion_pair.dart';
import 'package:talia_quran/features/quran/data/models/isar_ayah_note.dart';

import '../../helpers/isar_test_core.dart';

class _RejectingPreferenceStore extends InMemorySharedPreferencesStore {
  _RejectingPreferenceStore.withData(super.data) : super.withData();

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

  setUpAll(initializeIsarCoreForTests);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    directory = await Directory('.superpowers/tmp').createTemp('pair_backup_');
    source = await Isar.open(
      appIsarSchemas,
      directory: directory.path,
      name: 'source_${DateTime.now().microsecondsSinceEpoch}',
    );
    target = await Isar.open(
      appIsarSchemas,
      directory: directory.path,
      name: 'target_${DateTime.now().microsecondsSinceEpoch}',
    );
  });
  tearDown(() async {
    await source.close(deleteFromDisk: true);
    await target.close(deleteFromDisk: true);
    final root = Directory('.superpowers/tmp').absolute.path;
    expect(directory.absolute.path.startsWith(root), isTrue);
    await directory.delete(recursive: true);
  });

  Future<void> seed(Isar isar, String owner) => isar.writeTxn(() async {
    await isar.isarConfusionPairs.put(
      IsarConfusionPair()
        ..ownerId = owner
        ..audience = IsarConfusionPair.adultAudience
        ..targetKey = '2:255'
        ..otherKey = '3:2'
        ..count = 2
        ..firstAt = DateTime.utc(2026, 1, 1)
        ..lastAt = DateTime.utc(2026, 2, 1),
    );
    await isar.isarAyahNotes.put(
      IsarAyahNote()
        ..ownerId = owner
        ..surahId = 1
        ..ayahNumber = 1
        ..body = 'private'
        ..createdAt = DateTime.utc(2026)
        ..updatedAt = DateTime.utc(2026),
    );
  });

  Future<BackupPayload> collect() => BackupCollector(
    source,
    prefs,
    const FixedRecordOwnerProvider('owner-a'),
  ).collect(DateTime.utc(2026, 10, 20));

  test(
    'v3 roundtrip replaces, rather than adds, owner confusion pairs',
    () async {
      await seed(source, 'owner-a');
      final payload = await collect();
      await seed(target, 'owner-b');
      final restorer = BackupRestorer(
        target,
        prefs,
        const FixedRecordOwnerProvider('owner-b'),
      );

      expect(await restorer.restore(payload), BackupRestoreResult.restored);
      expect(await restorer.restore(payload), BackupRestoreResult.restored);
      final pairs = await target.isarConfusionPairs.where().findAll();
      expect(pairs, hasLength(1));
      expect(pairs.single.count, 2);
      expect(pairs.single.ownerId, 'owner-b');
      expect(
        (await target.isarAyahNotes.where().findAll()).single.ownerId,
        'owner-b',
      );
    },
  );

  test('a v2 backup (no pairs section) keeps every owner''s pairs', () async {
    await seed(source, 'owner-a');
    final current = await collect();
    final v2 = BackupPayload(
      schemaVersion: 2,
      createdAt: current.createdAt,
      sections: {
        for (final key in BackupSections.v2) key: current.sections[key],
      },
    );
    await seed(target, 'owner-b');
    await seed(target, 'owner-c');

    expect(
      await BackupRestorer(
        target,
        prefs,
        const FixedRecordOwnerProvider('owner-b'),
      ).restore(v2),
      BackupRestoreResult.restored,
    );
    final rows = await target.isarConfusionPairs.where().findAll();
    expect(rows.map((row) => row.ownerId).toSet(), {'owner-b', 'owner-c'});
  });

  test(
    'collector rejects a corrupt nonadult owner row instead of omitting it',
    () async {
      await seed(source, 'owner-a');
      await source.writeTxn(() async {
        await source.isarConfusionPairs.put(
          IsarConfusionPair()
            ..ownerId = 'owner-a'
            ..audience = 'kids'
            ..targetKey = '1:1'
            ..otherKey = '1:2'
            ..count = 1
            ..firstAt = DateTime.utc(2026)
            ..lastAt = DateTime.utc(2026),
        );
      });

      await expectLater(collect(), throwsA(isA<StateError>()));
    },
  );

  test(
    'malformed v3 pair is rejected before target pairs or notes change',
    () async {
      await seed(source, 'owner-a');
      await seed(target, 'owner-b');
      final current = await collect();
      final malformed = BackupPayload(
        schemaVersion: kBackupSchemaVersion,
        createdAt: current.createdAt,
        sections: {
          ...current.sections,
          BackupSections.confusionPairs: [
            {
              'ownerId': kBackupOwnerToken,
              'audience': 'adult',
              'targetKey': '2:255',
              'otherKey': '2:255',
              'count': 1,
              'firstAt': '2026-01-01T00:00:00.000Z',
              'lastAt': '2026-01-01T00:00:00.000Z',
            },
          ],
        },
      );

      expect(
        await BackupRestorer(
          target,
          prefs,
          const FixedRecordOwnerProvider('owner-b'),
        ).restore(malformed),
        BackupRestoreResult.invalidSections,
      );
      expect(await target.isarConfusionPairs.count(), 1);
      expect(
        (await target.isarAyahNotes.where().findAll()).single.body,
        'private',
      );
    },
  );

  test(
    'preference write failure rolls back both target pairs and notes',
    () async {
      await seed(source, 'owner-a');
      await prefs.setString('user_profile', '{"name":"source"}');
      final payload = await collect();
      await seed(target, 'owner-b');
      await target.writeTxn(() async {
        final pair = (await target.isarConfusionPairs.where().findAll()).single;
        pair.count = 9;
        await target.isarConfusionPairs.put(pair);
        final note = (await target.isarAyahNotes.where().findAll()).single;
        note.body = 'target before failure';
        await target.isarAyahNotes.put(note);
      });
      final store = _RejectingPreferenceStore.withData({
        'flutter.user_profile': '{"name":"target"}',
      });
      SharedPreferencesStorePlatform.instance = store;
      SharedPreferences.resetStatic();
      final failingPrefs = await SharedPreferences.getInstance();

      expect(
        await BackupRestorer(
          target,
          failingPrefs,
          const FixedRecordOwnerProvider('owner-b'),
        ).restore(payload),
        BackupRestoreResult.writeFailed,
      );
      final pair = (await target.isarConfusionPairs.where().findAll()).single;
      final note = (await target.isarAyahNotes.where().findAll()).single;
      expect(pair.count, 9);
      expect(pair.ownerId, 'owner-b');
      expect(note.body, 'target before failure');
    },
  );
}
