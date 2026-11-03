import '../../helpers/restore_test_admission.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/backup/backup_collector.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';
import 'package:talia_quran/core/backup/backup_restorer.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';
import 'package:talia_quran/core/backup/in_memory_restore_journal_store.dart';
import 'package:talia_quran/core/backup/portable_reading_backup_adapter.dart';
import 'package:talia_quran/core/backup/restore_recovery_journal.dart';
import 'package:talia_quran/core/backup/restore_store_rollbacks.dart';
import 'package:talia_quran/core/constants/surah_names.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/data/models/isar_ayah_note.dart';
import 'package:talia_quran/features/quran/domain/entities/bookmark_entry.dart';

import '../../helpers/isar_test_core.dart';

/// Preference store whose writes can be made to fail from a test.
class _HookStore extends InMemorySharedPreferencesStore {
  _HookStore.withData(super.data) : super.withData();

  bool failAll = false;
  bool Function(String key)? failKey;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final bare = key.substring('flutter.'.length);
    if (failAll || (failKey?.call(bare) ?? false)) return false;
    return super.setValue(valueType, key, value);
  }
}

/// Journal store whose state writes can fail on demand.
class _JournalStore extends InMemoryRestoreJournalStore {
  bool Function(String key, String value)? failWrite;

  @override
  Future<void> write(String ownerId, String key, String value) async {
    if (failWrite?.call(key, value) ?? false) {
      throw Exception('journal write failed');
    }
    return super.write(ownerId, key, value);
  }
}

void main() {
  setUpAll(initializeRestoreAdmissionForTests);
  late Directory directory;
  late Isar source;
  late Isar target;
  late _HookStore store;
  late SharedPreferences prefs;
  late _JournalStore journalStore;

  setUpAll(initializeIsarCoreForTests);
  setUp(() async {
    store = _HookStore.withData({});
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
    journalStore = _JournalStore();
    directory = await Directory('.superpowers/tmp').createTemp('reading_');
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
    await directory.delete(recursive: true);
  });

  BookmarkService bookmarksFor(String owner) =>
      BookmarkService(prefs, owner: FixedRecordOwnerProvider(owner));

  AppSessionService sessionFor(String owner) =>
      AppSessionService(prefs, owner: FixedRecordOwnerProvider(owner));

  PortableReadingBackupAdapter adapterFor(
    String owner, {
    bool resolvable = true,
  }) => PortableReadingBackupAdapter(
    bookmarks: bookmarksFor(owner),
    session: sessionFor(owner),
    resolve: (reference) async => resolvable
        ? BookmarkEntry(
            surahId: reference.surahId,
            surahName: SurahNames.nameAr(reference.surahId),
            ayahNumber: reference.ayahNumber,
            ayahText: 'corpus ${reference.surahId}:${reference.ayahNumber}',
            savedAt: reference.savedAt,
          )
        : null,
  );

  RestoreRecoveryJournal journal() => RestoreRecoveryJournal(journalStore);

  BackupRestorer restorerFor(String owner, {bool resolvable = true}) =>
      BackupRestorer(
        target,
        prefs,
        FixedRecordOwnerProvider(owner),
        reading: adapterFor(owner, resolvable: resolvable),
        journal: journal(),
        maintenancePermit: testRestorePermit,
      );

  Future<BackupPayload> collectAs(String owner) => BackupCollector(
    source,
    prefs,
    FixedRecordOwnerProvider(owner),
    reading: adapterFor(owner),
  ).collect(DateTime.utc(2026, 10, 31));

  BookmarkEntry entry(int surah, int ayah) => BookmarkEntry(
    surahId: surah,
    surahName: 'x',
    ayahNumber: ayah,
    ayahText: 'device text',
    savedAt: DateTime.utc(2026, 1, 1),
  );

  Future<Set<String>> liveRefs(String owner) async => {
    for (final b in await bookmarksFor(
      owner,
    ).exportPortable(expectedOwnerId: owner))
      '${b.surahId}:${b.ayahNumber}',
  };

  Future<void> seedSource() async {
    final bookmarks = bookmarksFor('owner-a');
    await bookmarks.toggle(entry(2, 255));
    await bookmarks.toggle(entry(36, 1));
    await sessionFor(
      'owner-a',
    ).saveQuranCheckpoint(expectedOwnerId: 'owner-a', pageNumber: 42);
  }

  Future<void> seedTargetNote(String body) => target.writeTxn(
    () => target.isarAyahNotes.put(
      IsarAyahNote()
        ..ownerId = 'owner-b'
        ..surahId = 1
        ..ayahNumber = 1
        ..body = body
        ..createdAt = DateTime.utc(2026)
        ..updatedAt = DateTime.utc(2026),
    ),
  );

  Future<String> targetNote() async =>
      (await target.isarAyahNotes.where().findAll()).single.body;

  test('v5 export carries references and a checkpoint, never text', () async {
    await seedSource();

    final payload = await collectAs('owner-a');

    expect(payload.schemaVersion, 5);
    expect(payload.sections.keys.toSet(), BackupSections.v5);
    expect(payload.sections[BackupSections.bookmarks], [
      {'surahId': 2, 'ayahNumber': 255, 'savedAt': '2026-01-01T00:00:00.000Z'},
      {'surahId': 36, 'ayahNumber': 1, 'savedAt': '2026-01-01T00:00:00.000Z'},
    ]);
    expect(payload.sections[BackupSections.readingCheckpoint], {
      'pageNumber': 42,
    });
    expect(decodeBackup(encodeBackup(payload)).payload, payload);
  });

  test('v5 roundtrip adds references and the checkpoint', () async {
    await seedSource();
    final payload = await collectAs('owner-a');
    await bookmarksFor('owner-b').toggle(entry(3, 1));

    final result = await restorerFor('owner-b').restore(payload);

    expect(result, BackupRestoreResult.restored);
    expect(await liveRefs('owner-b'), {'2:255', '36:1', '3:1'});
    expect(
      (await sessionFor(
        'owner-b',
      ).exportQuranCheckpoint(expectedOwnerId: 'owner-b'))?.pageNumber,
      42,
    );
    final restored = bookmarksFor(
      'owner-b',
    ).getAll().firstWhere((b) => b.surahId == 2);
    expect(restored.ayahText, 'corpus 2:255');
    expect(restored.isSynced, isFalse);
    // The restoring journal leaves nothing behind.
    expect(
      (await journal().recoverBeforeReady(
        activeOwnerId: 'owner-b',
        rollbacks: const {},
      )).status,
      RestoreRecoveryStatus.clean,
    );
  });

  test('restoring twice does not duplicate bookmarks', () async {
    await seedSource();
    final payload = await collectAs('owner-a');
    final restorer = restorerFor('owner-b');

    await restorer.restore(payload);
    await restorer.restore(payload);

    expect(bookmarksFor('owner-b').getAll(), hasLength(2));
  });

  test('a logically deleted bookmark is never revived by a file', () async {
    await seedSource();
    final payload = await collectAs('owner-a');
    final b = bookmarksFor('owner-b');
    await b.toggle(entry(2, 255));
    await b.toggle(entry(2, 255));
    expect(await liveRefs('owner-b'), isEmpty);

    await restorerFor('owner-b').restore(payload);

    expect(await liveRefs('owner-b'), {'36:1'});
  });

  test('an older file keeps the device bookmarks and checkpoint', () async {
    await seedSource();
    final current = await collectAs('owner-a');
    final v4 = BackupPayload(
      schemaVersion: 4,
      createdAt: current.createdAt,
      sections: {
        for (final key in BackupSections.v4) key: current.sections[key],
      },
    );
    await bookmarksFor('owner-b').toggle(entry(3, 1));
    await sessionFor(
      'owner-b',
    ).saveQuranCheckpoint(expectedOwnerId: 'owner-b', pageNumber: 7);

    final result = await restorerFor('owner-b').restore(v4);

    expect(result, BackupRestoreResult.restored);
    expect(await liveRefs('owner-b'), {'3:1'});
    expect(
      (await sessionFor(
        'owner-b',
      ).exportQuranCheckpoint(expectedOwnerId: 'owner-b'))?.pageNumber,
      7,
    );
  });

  test('a file without a checkpoint keeps the device position', () async {
    await bookmarksFor('owner-a').toggle(entry(2, 255));
    final payload = await collectAs('owner-a');
    await sessionFor(
      'owner-b',
    ).saveQuranCheckpoint(expectedOwnerId: 'owner-b', pageNumber: 7);

    await restorerFor('owner-b').restore(payload);

    expect(
      (await sessionFor(
        'owner-b',
      ).exportQuranCheckpoint(expectedOwnerId: 'owner-b'))?.pageNumber,
      7,
    );
  });

  test('an invalid reference rejects the file before any write', () async {
    await seedSource();
    final current = await collectAs('owner-a');
    await seedTargetNote('keep');
    final tampered = BackupPayload(
      schemaVersion: 5,
      createdAt: current.createdAt,
      sections: {
        ...current.sections,
        BackupSections.bookmarks: [
          {
            'surahId': 2,
            'ayahNumber': 9999,
            'savedAt': '2026-01-01T00:00:00.000Z',
          },
        ],
      },
    );

    final result = await restorerFor('owner-b').restore(tampered);

    expect(result, BackupRestoreResult.invalidSections);
    expect(await targetNote(), 'keep');
    expect(await liveRefs('owner-b'), isEmpty);
  });

  test('duplicate references and a bad page reject the file', () async {
    await seedSource();
    final current = await collectAs('owner-a');
    BackupPayload with_(String key, Object? value) => BackupPayload(
      schemaVersion: 5,
      createdAt: current.createdAt,
      sections: {...current.sections, key: value},
    );
    const ref = {
      'surahId': 2,
      'ayahNumber': 255,
      'savedAt': '2026-01-01T00:00:00.000Z',
    };

    expect(
      await restorerFor(
        'owner-b',
      ).restore(with_(BackupSections.bookmarks, [ref, ref])),
      BackupRestoreResult.invalidSections,
    );
    expect(
      await restorerFor(
        'owner-b',
      ).restore(with_(BackupSections.readingCheckpoint, {'pageNumber': 605})),
      BackupRestoreResult.invalidSections,
    );
    expect(await liveRefs('owner-b'), isEmpty);
  });

  test('a reference the corpus cannot resolve rejects the file', () async {
    await seedSource();
    final payload = await collectAs('owner-a');
    await seedTargetNote('keep');

    final result = await restorerFor(
      'owner-b',
      resolvable: false,
    ).restore(payload);

    expect(result, BackupRestoreResult.invalidSections);
    expect(await targetNote(), 'keep');
  });

  test('a failed write rolls bookmarks, checkpoint and Isar back', () async {
    await seedSource();
    final payload = await collectAs('owner-a');
    await seedTargetNote('keep');
    await bookmarksFor('owner-b').toggle(entry(3, 1));
    await sessionFor(
      'owner-b',
    ).saveQuranCheckpoint(expectedOwnerId: 'owner-b', pageNumber: 7);
    // Only the restore's own write fails; the rollback may rewrite the key.
    var failed = false;
    store.failKey = (key) {
      if (failed || !key.startsWith('quran_reading_checkpoint_owner_')) {
        return false;
      }
      return failed = true;
    };

    final result = await restorerFor('owner-b').restore(payload);
    store.failKey = null;

    expect(result, BackupRestoreResult.writeFailed);
    expect(await targetNote(), 'keep');
    expect(await liveRefs('owner-b'), {'3:1'});
    expect(
      (await sessionFor(
        'owner-b',
      ).exportQuranCheckpoint(expectedOwnerId: 'owner-b'))?.pageNumber,
      7,
    );
    expect(journalStore, isA<InMemoryRestoreJournalStore>());
    expect(
      (await journal().recoverBeforeReady(
        activeOwnerId: 'owner-b',
        rollbacks: const {},
      )).status,
      RestoreRecoveryStatus.clean,
    );
  });

  test('no rollback point means nothing is changed', () async {
    await seedSource();
    final payload = await collectAs('owner-a');
    await seedTargetNote('keep');
    journalStore.failWrite = (key, value) => key == 'manifest';

    final result = await restorerFor('owner-b').restore(payload);

    expect(result, BackupRestoreResult.protectionUnavailable);
    expect(await targetNote(), 'keep');
    expect(await liveRefs('owner-b'), isEmpty);
  });

  test('a restore that cannot roll back is recovered at next start', () async {
    await seedSource();
    final payload = await collectAs('owner-a');
    await seedTargetNote('keep');
    await bookmarksFor('owner-b').toggle(entry(3, 1));
    await sessionFor(
      'owner-b',
    ).saveQuranCheckpoint(expectedOwnerId: 'owner-b', pageNumber: 7);
    final restorer = restorerFor('owner-b');
    // The commit marker fails, and the device's preferences then refuse the
    // rollback writes, as if the process died with every store half-written.
    journalStore.failWrite = (key, value) {
      if (key == 'state' && value.contains('committed')) {
        store.failAll = true;
        return true;
      }
      return false;
    };

    final result = await restorer.restore(payload);

    expect(result, BackupRestoreResult.writeFailed);
    expect(
      await restorer.restore(payload),
      BackupRestoreResult.recoveryBlocked,
    );
    // Bookmarks were written before the failure and the stuck rollback left
    // them there.
    expect(await liveRefs('owner-b'), {'3:1', '2:255', '36:1'});

    // "Restart": a fresh journal over the same durable store recovers.
    store.failAll = false;
    journalStore.failWrite = null;
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
    final rollbacks = RestoreStoreRollbacks(
      target,
      prefs,
      adapterFor('owner-b'),
    );
    final recovery = await journal().recoverBeforeReady(
      activeOwnerId: 'owner-b',
      rollbacks: rollbacks.registry,
    );

    expect(recovery.status, RestoreRecoveryStatus.rolledBack);
    expect(await targetNote(), 'keep');
    expect(await liveRefs('owner-b'), {'3:1'});
    expect(
      (await sessionFor(
        'owner-b',
      ).exportQuranCheckpoint(expectedOwnerId: 'owner-b'))?.pageNumber,
      7,
    );
  });
}
