import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/in_memory_restore_journal_store.dart';
import 'package:talia_quran/core/backup/restore_operation_gate.dart';
import 'package:talia_quran/core/backup/restore_preferences_snapshot.dart';
import 'package:talia_quran/core/backup/restore_recovery_journal.dart';
import 'package:talia_quran/core/backup/restore_startup_recovery.dart';
import 'package:talia_quran/core/backup/restore_store_rollbacks.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';

/// Only the preference rollback is exercised; Isar is never touched.
class _NoIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Isar must not be used');
}

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

class _UnreadableStore extends InMemoryRestoreJournalStore {
  @override
  Future<String?> read(String ownerId, String key) =>
      throw Exception('keystore unavailable');
}

void main() {
  test('unreadable recovery cannot publish application readiness', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final owner = _MutableOwner('a');
    final recovery = RestoreStartupRecovery(
      journal: RestoreRecoveryJournal(_UnreadableStore()),
      rollbacks: RestoreStoreRollbacks(_NoIsar(), prefs, null),
      owner: owner,
      gate: RestoreOperationGate(owner),
    );
    var admitted = false;
    await expectLater(
      recovery.requireReady().then((_) {
        admitted = true;
      }),
      throwsA(isA<RestoreBlockedException>()),
    );
    expect(admitted, isFalse);
  });

  late SharedPreferences prefs;
  late InMemoryRestoreJournalStore journalStore;
  late _MutableOwner owner;
  late RestoreOperationGate gate;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'read_pages': 'original'});
    prefs = await SharedPreferences.getInstance();
    journalStore = InMemoryRestoreJournalStore();
    owner = _MutableOwner('a');
    gate = RestoreOperationGate(owner);
  });

  RestoreStartupRecovery recovery({
    InMemoryRestoreJournalStore? store,
    RestoreRecoveryJournal? journal,
  }) => RestoreStartupRecovery(
    journal: journal ?? RestoreRecoveryJournal(store ?? journalStore),
    rollbacks: RestoreStoreRollbacks(_NoIsar(), prefs, null),
    owner: owner,
    gate: gate,
  );

  Future<void> leavePreparedPrefsJournal() async {
    final snapshot = RestorePreferencesSnapshot(prefs).capture(['read_pages']);
    await RestoreRecoveryJournal(
      journalStore,
    ).prepare(destinationOwner: 'a', snapshots: {RestorePart.prefs: snapshot});
    await prefs.setString('read_pages', 'half-restored');
  }

  test('a clean start leaves the gate open', () async {
    final result = await recovery().recover();

    expect(result.status, RestoreRecoveryStatus.clean);
    expect(gate.isBlocked, isFalse);
  });

  test('an interrupted restore is rolled back before ready', () async {
    await leavePreparedPrefsJournal();

    final result = await recovery().recover();

    expect(result.status, RestoreRecoveryStatus.rolledBack);
    expect(prefs.getString('read_pages'), 'original');
    expect(gate.isBlocked, isFalse);
  });

  test(
    'an unprovable state blocks restores and sync until it recovers',
    () async {
      await leavePreparedPrefsJournal();
      owner.currentOwnerId = 'b';

      final blocked = await recovery().recover();

      expect(blocked.status, RestoreRecoveryStatus.blocked);
      expect(gate.isBlocked, isTrue);
      await expectLater(
        gate.run(expectedOwnerId: 'b', operation: () async {}),
        throwsA(isA<RestoreBlockedException>()),
      );
      expect(prefs.getString('read_pages'), 'half-restored');

      owner.currentOwnerId = 'a';
      final recovered = await recovery().recover();

      expect(recovered.status, RestoreRecoveryStatus.rolledBack);
      expect(gate.isBlocked, isFalse);
      expect(prefs.getString('read_pages'), 'original');
    },
  );

  test('hasUnfinished only looks: it never rolls anything back', () async {
    await leavePreparedPrefsJournal();

    expect(await recovery().hasUnfinished(), isTrue);

    expect(prefs.getString('read_pages'), 'half-restored');
    expect(gate.isBlocked, isTrue);
  });

  test('hasUnfinished is false for a clean store', () async {
    expect(await recovery().hasUnfinished(), isFalse);
    expect(gate.isBlocked, isFalse);
  });

  test('an unreadable journal store counts as unfinished', () async {
    final unreadable = RestoreRecoveryJournal(_UnreadableStore());

    expect(await recovery(journal: unreadable).hasUnfinished(), isTrue);
    expect(gate.isBlocked, isTrue);

    final result = await recovery(journal: unreadable).recover();
    expect(result.status, RestoreRecoveryStatus.blocked);
  });
}
