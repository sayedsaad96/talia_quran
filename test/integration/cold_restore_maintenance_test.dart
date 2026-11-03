import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/backup_collector.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';
import 'package:talia_quran/core/backup/backup_restorer.dart';
import 'package:talia_quran/core/backup/in_memory_restore_journal_store.dart';
import 'package:talia_quran/core/backup/restore_maintenance_session.dart';
import 'package:talia_quran/core/backup/restore_parent_pin_guard.dart';
import 'package:talia_quran/core/backup/restore_preferences_snapshot.dart';
import 'package:talia_quran/core/backup/restore_recovery_journal.dart';
import 'package:talia_quran/core/backup/restore_request_store.dart';
import 'package:talia_quran/core/backup/restore_store_rollbacks.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/identity/guest_store_ownership.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/security/parent_pin_secure_store.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/features/quran/data/repositories/reading_checkpoint_repository_impl.dart';

import '../helpers/isar_test_core.dart';
import '../helpers/restore_test_admission.dart';

class _Pin extends RestoreParentPinGuard {
  _Pin(SharedPreferences prefs)
    : super(prefs: prefs, pinStore: FlutterParentPinSecureStore());
  bool protected = false;
  @override
  Future<bool> requiresPin() async => protected;
  @override
  Future<bool> verify(String pin) async => pin == '1234';
}

void main() {
  late Directory directory;
  late SharedPreferences prefs;
  late InMemoryRestoreJournalStore secure;
  late _Pin pin;
  late String request;
  setUpAll(() async {
    await initializeIsarCoreForTests();
    await initializeRestoreAdmissionForTests();
  });
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({
      ExperienceFeature.recoverableBackupRestore.storageKey: true,
      AppSessionService.quranCheckpointKeyFor('local'): 12,
      ReadingCheckpointRepositoryImpl.guestStorageKey:
          '{"page":12,"revision":0}',
    });
    prefs = await SharedPreferences.getInstance();
    secure = InMemoryRestoreJournalStore();
    pin = _Pin(prefs);
    directory = await Directory.systemTemp.createTemp('cold_maintenance_');
    request = await RestoreRequestStore(prefs).schedule();
  });
  tearDown(() async {
    await Isar.getInstance()?.close();
    await directory.delete(recursive: true);
    await getIt.reset();
  });
  Future<RestoreMaintenanceSession> open() => RestoreMaintenanceSession.open(
    testRestorePermit,
    preferences: prefs,
    secureStore: secure,
    directory: directory.path,
    pinGuard: pin,
  );
  Future<BackupPayload> payload() async {
    final base = await BackupCollector(
      Isar.getInstance()!,
      prefs,
      const FixedRecordOwnerProvider('local'),
    ).collect(DateTime.utc(2026, 11, 2));
    return BackupPayload(
      schemaVersion: 5,
      createdAt: base.createdAt,
      sections: {
        ...base.sections,
        'bookmarks': <Object>[],
        'readingCheckpoint': {'pageNumber': 42},
      },
    );
  }

  test(
    'private graph restores both checkpoint stores and consumes request once',
    () async {
      final session = await open();
      expect(getIt.isRegistered<Isar>(), isFalse);
      final backup = await payload();
      expect(
        await session.restore(request, backup),
        BackupRestoreResult.restored,
      );
      expect(await session.requests.pendingId(), isNull);
      expect(
        await session.restore(request, backup),
        BackupRestoreResult.protectionUnavailable,
      );
      expect(
        prefs.getInt(AppSessionService.quranCheckpointKeyFor('local')),
        42,
      );
      expect(
        prefs.getString(ReadingCheckpointRepositoryImpl.guestStorageKey),
        contains('42'),
      );
      await session.closeForNormalStartup();
      expect(await testRestorePermit.validate(), isTrue);
      expect(Isar.getInstance(), isNull);
    },
  );
  test(
    'overlapping replacement and close cannot reuse confirmation or PIN',
    () async {
      final session = await open();
      final backup = await payload();
      final first = session.restore(request, backup);
      final second = session.restore(request, backup);
      await expectLater(session.closeForNormalStartup(), throwsStateError);
      expect(await first, BackupRestoreResult.restored);
      expect(await second, BackupRestoreResult.protectionUnavailable);
      await session.closeForNormalStartup();
    },
  );
  test(
    'recovery precedes request screen and restores original absent/present prefs',
    () async {
      await RestoreRecoveryJournal(secure).prepare(
        destinationOwner: 'local',
        snapshots: {
          RestorePart.prefs: RestorePreferencesSnapshot(
            prefs,
          ).capture({'restore_test_value'}),
        },
      );
      await prefs.setInt('restore_test_value', 42);
      final session = await open();
      expect(prefs.containsKey('restore_test_value'), isFalse);
      expect(await session.journal.isCleanForAdmission(), isTrue);
      expect(await session.requests.pendingId(), request);
      await session.closeForNormalStartup();
    },
  );
  test(
    'preserved account refuses database opening and can cancel clean request',
    () async {
      await GuestStoreOwnership(prefs).markAccountActive();
      final session = await open();
      expect(Isar.getInstance(), isNull);
      expect(await session.canReplace, isFalse);
      expect(await session.requests.pendingId(), request);
      await session.closeForNormalStartup();
      expect(await session.requests.pendingId(), isNull);
      expect(prefs.getBool(GuestStoreOwnership.accountKey), isTrue);
    },
  );
  test(
    'ambiguous account cannot bypass unfinished journal by cancelling',
    () async {
      await GuestStoreOwnership(prefs).markAccountActive();
      await RestoreRecoveryJournal(secure).prepare(
        destinationOwner: 'local',
        snapshots: {
          RestorePart.prefs: RestorePreferencesSnapshot(
            prefs,
          ).capture({'restore_test_value'}),
        },
      );
      final session = await open();
      expect(Isar.getInstance(), isNull);
      await expectLater(session.closeForNormalStartup(), throwsStateError);
      expect(await session.requests.pendingId(), request);
    },
  );
  test(
    'PIN and rollout off do not consume the request or replace data',
    () async {
      final session = await open();
      pin.protected = true;
      final backup = await payload();
      expect(
        await session.restore(request, backup),
        BackupRestoreResult.protectionUnavailable,
      );
      expect(await session.requests.pendingId(), request);
      expect(await session.verifyPin('1234'), isTrue);
      await prefs.setBool(
        ExperienceFeature.recoverableBackupRestore.storageKey,
        false,
      );
      expect(
        await session.restore(request, backup),
        BackupRestoreResult.protectionUnavailable,
      );
      expect(
        prefs.getInt(AppSessionService.quranCheckpointKeyFor('local')),
        12,
      );
      expect(await session.requests.pendingId(), request);
      await session.closeForNormalStartup();
    },
  );
}
