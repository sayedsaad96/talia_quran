import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/backup/backup_collector.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';
import 'package:talia_quran/core/backup/backup_restorer.dart';
import 'package:talia_quran/core/backup/in_memory_restore_journal_store.dart';
import 'package:talia_quran/core/backup/portable_reading_backup_adapter.dart';
import 'package:talia_quran/core/backup/portable_reading_data.dart';
import 'package:talia_quran/core/backup/restore_recovery_journal.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/data/repositories/reading_checkpoint_repository_impl.dart';
import 'package:talia_quran/features/quran/domain/repositories/reading_checkpoint_repository.dart';

import '../../helpers/isar_test_core.dart';
import '../../helpers/restore_test_admission.dart';

class _Writes extends InMemorySharedPreferencesStore {
  _Writes() : super.withData({});
  String? failNext;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.$failNext') {
      failNext = null;
      return false;
    }
    return super.setValue(type, key, value);
  }
}

class _NoNetwork implements ReadingCheckpointRemote {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('No network');
}

void main() {
  const owner = FixedRecordOwnerProvider('local');
  late SharedPreferences prefs;
  late _Writes writes;
  late Directory directory;
  late Isar isar;
  late ReadingCheckpointRepositoryImpl repository;
  late PortableReadingBackupAdapter reading;
  setUpAll(() async {
    await initializeIsarCoreForTests();
    await initializeRestoreAdmissionForTests();
  });
  setUp(() async {
    writes = _Writes();
    SharedPreferencesStorePlatform.instance = writes;
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
    final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    repository = ReadingCheckpointRepositoryImpl(
      prefs: prefs,
      owner: owner,
      barrier: barrier,
      secureStore: InMemoryRestoreJournalStore(),
      remote: _NoNetwork(),
    );
    final session = AppSessionService(
      prefs,
      owner: owner,
      checkpointPreferenceKeys: (_) => [
        ReadingCheckpointRepositoryImpl.guestStorageKey,
      ],
      checkpointReader: (id, lease) async {
        final value = await repository.readUnderLease(
          expectedOwnerId: id,
          lease: lease,
        );
        return value == null
            ? null
            : QuranReadingCheckpoint(pageNumber: value.pageNumber);
      },
      checkpointWriter: (id, page, lease) => repository.writeUnderLease(
        expectedOwnerId: id,
        pageNumber: page,
        lease: lease,
      ),
    );
    reading = PortableReadingBackupAdapter(
      bookmarks: BookmarkService(prefs, owner: owner),
      session: session,
      resolve: (_) async => null,
    );
    directory = await Directory.systemTemp.createTemp('guest_restore_');
    isar = await Isar.open(
      appIsarSchemas,
      directory: directory.path,
      name: 'guest_${DateTime.now().microsecondsSinceEpoch}',
    );
  });
  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });
  Future<BackupPayload> payload() async {
    final base = await BackupCollector(
      isar,
      prefs,
      owner,
      reading: reading,
    ).collect(DateTime.utc(2026, 11, 2));
    return BackupPayload(
      schemaVersion: 5,
      createdAt: base.createdAt,
      sections: {
        ...base.sections,
        'readingCheckpoint': {'pageNumber': 42},
      },
    );
  }

  BackupRestorer restorer({bool admitted = true}) => BackupRestorer(
    isar,
    prefs,
    owner,
    reading: reading,
    journal: RestoreRecoveryJournal(InMemoryRestoreJournalStore()),
    maintenancePermit: admitted ? testRestorePermit : null,
  );
  test(
    'full replacement without exclusive maintenance changes nothing',
    () async {
      await repository.saveLocal(expectedOwnerId: 'local', pageNumber: 12);
      expect(
        await restorer(admitted: false).restore(await payload()),
        BackupRestoreResult.protectionUnavailable,
      );
      expect(
        (await repository.readLocal(expectedOwnerId: 'local'))!.pageNumber,
        12,
      );
    },
  );
  test(
    'v5 restores the authoritative guest position and compatibility cache',
    () async {
      await repository.saveLocal(expectedOwnerId: 'local', pageNumber: 12);
      expect(
        await restorer().restore(await payload()),
        BackupRestoreResult.restored,
      );
      expect(
        (await repository.readLocal(expectedOwnerId: 'local'))!.pageNumber,
        42,
      );
      expect(
        prefs.getInt(AppSessionService.quranCheckpointKeyFor('local')),
        42,
      );
    },
  );
  for (final oldPage in <int?>[null, 12]) {
    test(
      'failed checkpoint write restores raw presence and value ($oldPage)',
      () async {
        if (oldPage != null) {
          await repository.saveLocal(
            expectedOwnerId: 'local',
            pageNumber: oldPage,
          );
        }
        final raw = prefs.get(ReadingCheckpointRepositoryImpl.guestStorageKey);
        final backup = await payload();
        writes.failNext = AppSessionService.quranCheckpointKeyFor('local');
        expect(
          await restorer().restore(backup),
          BackupRestoreResult.writeFailed,
        );
        expect(prefs.get(ReadingCheckpointRepositoryImpl.guestStorageKey), raw);
        expect(
          prefs.getInt(AppSessionService.quranCheckpointKeyFor('local')),
          oldPage,
        );
      },
    );
  }
}
