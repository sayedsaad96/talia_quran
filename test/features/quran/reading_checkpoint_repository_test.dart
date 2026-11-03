import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/security/encrypted_account_preferences_store.dart';
import 'package:talia_quran/features/quran/data/repositories/reading_checkpoint_repository_impl.dart';
import 'package:talia_quran/features/quran/domain/repositories/reading_checkpoint_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/reading_checkpoint_cubit.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/backup/portable_reading_data.dart';

class SecureStore implements EncryptedAccountPreferencesStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String ownerId, String key) async =>
      values['$ownerId:$key'];
  @override
  Future<void> write(String ownerId, String key, String value) async {
    values['$ownerId:$key'] = value;
  }

  @override
  Future<void> delete(String ownerId, String key) async {
    values.remove('$ownerId:$key');
  }
}

class MutableOwner implements RecordOwnerProvider {
  @override
  String currentOwnerId = 'a';
  @override
  bool get isSignedIn => true;
}

class Remote implements ReadingCheckpointRemote {
  RemoteCheckpoint? current;
  final receipts = <String, RemoteCheckpoint>{};
  Completer<void>? gate;
  bool loseResponse = false;
  @override
  Future<RemoteCheckpoint?> get({required String expectedOwnerId}) async =>
      current;
  @override
  Future<CheckpointRemoteResult> put({
    required String expectedOwnerId,
    required int pageNumber,
    required int expectedRevision,
    required String mutationId,
  }) async {
    if (gate != null) await gate!.future;
    if (receipts[mutationId] case final receipt?) {
      return CheckpointRemoteResult.accepted(receipt);
    }
    if ((current?.revision ?? 0) != expectedRevision) {
      return CheckpointRemoteResult.conflict(current);
    }
    final accepted = RemoteCheckpoint(pageNumber, expectedRevision + 1);
    receipts[mutationId] = accepted;
    current = accepted;
    if (loseResponse) {
      loseResponse = false;
      throw StateError('offline');
    }
    return CheckpointRemoteResult.accepted(accepted);
  }
}

class DelayedPullRemote extends Remote {
  final pendingPull = Completer<RemoteCheckpoint?>();
  final requested = Completer<void>();
  @override
  Future<RemoteCheckpoint?> get({required String expectedOwnerId}) {
    if (!requested.isCompleted) {
      requested.complete();
      return pendingPull.future;
    }
    return super.get(expectedOwnerId: expectedOwnerId);
  }
}

void main() {
  test(
    'a historical accepted receipt reconciles the current server position',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const owner = FixedRecordOwnerProvider('a');
      final remote = Remote()..loseResponse = true;
      final repo = ReadingCheckpointRepositoryImpl(
        prefs: prefs,
        owner: owner,
        barrier: AccountDataBarrier.forPreferences(prefs)..owner = owner,
        secureStore: SecureStore(),
        remote: remote,
      );
      await repo.saveLocal(expectedOwnerId: 'a', pageNumber: 12);
      expect(
        (await repo.sync(expectedOwnerId: 'a')).status,
        CheckpointSyncStatus.pending,
      );
      remote.current = const RemoteCheckpoint(99, 2);
      final replay = await repo.sync(expectedOwnerId: 'a');
      expect(replay.status, CheckpointSyncStatus.synced);
      expect(replay.local!.pageNumber, 99);
      expect(replay.local!.serverRevision, 2);
    },
  );

  test(
    'missing remote copy is never reported as a synchronized local page',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const owner = FixedRecordOwnerProvider('a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final repo = ReadingCheckpointRepositoryImpl(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        secureStore: SecureStore(),
        remote: Remote(),
      );
      await barrier.run(
        (lease) => repo.restoreUnderLease(
          expectedOwnerId: 'a',
          snapshot: const LocalReadingCheckpoint(
            pageNumber: 12,
            serverRevision: 7,
          ),
          lease: lease,
        ),
      );
      final result = await repo.sync(expectedOwnerId: 'a');
      expect(result.status, CheckpointSyncStatus.unavailable);
      expect(result.local!.pageNumber, 12);
    },
  );

  test('an old conflict choice cannot discard a newer local save', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('a');
    final remote = Remote()..current = const RemoteCheckpoint(22, 3);
    final repo = ReadingCheckpointRepositoryImpl(
      prefs: prefs,
      owner: owner,
      barrier: AccountDataBarrier.forPreferences(prefs)..owner = owner,
      secureStore: SecureStore(),
      remote: remote,
    );
    await repo.saveLocal(expectedOwnerId: 'a', pageNumber: 10);
    final shown = (await repo.sync(expectedOwnerId: 'a')).local!;
    await repo.saveLocal(expectedOwnerId: 'a', pageNumber: 30);
    await expectLater(
      repo.resolveConflict(
        expectedOwnerId: 'a',
        expectedMutationId: shown.pendingMutationId!,
        expectedLocalPage: shown.pageNumber,
        seenRemote: remote.current!,
        useLocal: false,
      ),
      throwsStateError,
    );
    expect((await repo.readLocal(expectedOwnerId: 'a'))!.pageNumber, 30);
  });
  test(
    'a delayed pull never rewinds a newer acknowledged local checkpoint',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const owner = FixedRecordOwnerProvider('a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final remote = DelayedPullRemote()
        ..current = const RemoteCheckpoint(10, 7);
      final repo = ReadingCheckpointRepositoryImpl(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        secureStore: SecureStore(),
        remote: remote,
      );
      await barrier.run(
        (lease) => repo.restoreUnderLease(
          expectedOwnerId: 'a',
          snapshot: const LocalReadingCheckpoint(
            pageNumber: 10,
            serverRevision: 7,
          ),
          lease: lease,
        ),
      );
      final oldPull = repo.sync(expectedOwnerId: 'a');
      await remote.requested.future;
      await repo.saveLocal(expectedOwnerId: 'a', pageNumber: 20);
      expect(
        (await repo.sync(expectedOwnerId: 'a')).status,
        CheckpointSyncStatus.synced,
      );
      remote.pendingPull.complete(const RemoteCheckpoint(10, 7));
      await oldPull;
      final saved = await repo.readLocal(expectedOwnerId: 'a');
      expect(saved!.pageNumber, 20);
      expect(saved.serverRevision, 8);
      expect(saved.pendingMutationId, isNull);
    },
  );

  test(
    'session export and explicit cloud conflict choice use the same authority',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final owner = MutableOwner();
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final remote = Remote()..current = const RemoteCheckpoint(10, 3);
      final repo = ReadingCheckpointRepositoryImpl(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        secureStore: SecureStore(),
        remote: remote,
      );
      final session = AppSessionService(
        prefs,
        owner: owner,
        checkpointReader: (id, lease) async {
          final state = await repo.readUnderLease(
            expectedOwnerId: id,
            lease: lease,
          );
          return state == null
              ? null
              : QuranReadingCheckpoint(pageNumber: state.pageNumber);
        },
        checkpointWriter: (id, page, lease) => repo.writeUnderLease(
          expectedOwnerId: id,
          pageNumber: page,
          lease: lease,
        ),
      );
      await session.saveCurrentQuranCheckpoint(22);
      final cubit = ReadingCheckpointCubit(repo, owner, barrier);
      await cubit.sync();
      expect(cubit.state.result!.status, CheckpointSyncStatus.conflict);
      expect(
        (await session.exportQuranCheckpoint(expectedOwnerId: 'a'))!.pageNumber,
        22,
      );
      await cubit.choose(false);
      expect(cubit.state.result!.status, CheckpointSyncStatus.synced);
      expect(
        (await session.exportQuranCheckpoint(expectedOwnerId: 'a'))!.pageNumber,
        10,
      );
      expect(session.getLastRestorableLocation(), '/quran/page/10');
      barrier.invalidate();
      owner.currentOwnerId = 'b';
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.result, isNull);
      await cubit.close();
    },
  );

  test(
    'rollback under the held lease restores the pending mutation exactly',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const owner = FixedRecordOwnerProvider('a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final repo = ReadingCheckpointRepositoryImpl(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        secureStore: SecureStore(),
        remote: Remote(),
      );
      await repo.saveLocal(expectedOwnerId: 'a', pageNumber: 12);
      await barrier.run((lease) async {
        final snapshot = await repo.readUnderLease(
          expectedOwnerId: 'a',
          lease: lease,
        );
        await repo.writeUnderLease(
          expectedOwnerId: 'a',
          pageNumber: 20,
          lease: lease,
        );
        await repo.restoreUnderLease(
          expectedOwnerId: 'a',
          snapshot: snapshot,
          lease: lease,
        );
        final restored = await repo.readUnderLease(
          expectedOwnerId: 'a',
          lease: lease,
        );
        expect(restored!.pageNumber, 12);
        expect(restored.pendingMutationId, snapshot!.pendingMutationId);
        expect(restored.serverRevision, snapshot.serverRevision);
      });
    },
  );
  test(
    'an A to B to A barrier invalidation rejects a delayed acknowledgement',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final owner = MutableOwner();
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final remote = Remote()..gate = Completer<void>();
      final repo = ReadingCheckpointRepositoryImpl(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        secureStore: SecureStore(),
        remote: remote,
      );
      await repo.saveLocal(expectedOwnerId: 'a', pageNumber: 12);
      final sync = repo.sync(expectedOwnerId: 'a');
      await Future<void>.delayed(Duration.zero);
      barrier.invalidate();
      owner.currentOwnerId = 'b';
      owner.currentOwnerId = 'a';
      remote.gate!.complete();
      expect((await sync).status, CheckpointSyncStatus.unavailable);
    },
  );
  test('lost response is retried without another server revision', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('a');
    final remote = Remote()..loseResponse = true;
    final store = SecureStore();
    ReadingCheckpointRepositoryImpl device() => ReadingCheckpointRepositoryImpl(
      prefs: prefs,
      owner: owner,
      barrier: AccountDataBarrier.forPreferences(prefs)..owner = owner,
      secureStore: store,
      remote: remote,
    );
    await device().saveLocal(expectedOwnerId: 'a', pageNumber: 12);
    expect(
      (await device().sync(expectedOwnerId: 'a')).status,
      CheckpointSyncStatus.pending,
    );
    expect(
      (await device().sync(expectedOwnerId: 'a')).status,
      CheckpointSyncStatus.synced,
    );
    expect(remote.current!.revision, 1);
    expect(remote.receipts, hasLength(1));
  });
  test('two devices conflict and preserve the pending local page', () async {
    const owner = FixedRecordOwnerProvider('a');
    final remote = Remote()..current = const RemoteCheckpoint(10, 7);
    Future<ReadingCheckpointRepositoryImpl> device() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      return ReadingCheckpointRepositoryImpl(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        secureStore: SecureStore(),
        remote: remote,
      );
    }

    final first = await device(), second = await device();
    expect(
      (await first.sync(expectedOwnerId: 'a')).status,
      CheckpointSyncStatus.synced,
    );
    expect(
      (await second.sync(expectedOwnerId: 'a')).status,
      CheckpointSyncStatus.synced,
    );
    await first.saveLocal(expectedOwnerId: 'a', pageNumber: 20);
    await second.saveLocal(expectedOwnerId: 'a', pageNumber: 30);
    expect(
      (await first.sync(expectedOwnerId: 'a')).status,
      CheckpointSyncStatus.synced,
    );
    final conflict = await second.sync(expectedOwnerId: 'a');
    expect(conflict.status, CheckpointSyncStatus.conflict);
    expect(conflict.local!.pageNumber, 30);
    expect(conflict.remote!.pageNumber, 20);
  });
  test('new local save during upload remains pending', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('a');
    final remote = Remote()..gate = Completer<void>();
    final repo = ReadingCheckpointRepositoryImpl(
      prefs: prefs,
      owner: owner,
      barrier: AccountDataBarrier.forPreferences(prefs)..owner = owner,
      secureStore: SecureStore(),
      remote: remote,
    );
    await repo.saveLocal(expectedOwnerId: 'a', pageNumber: 12);
    final sync = repo.sync(expectedOwnerId: 'a');
    await Future<void>.delayed(Duration.zero);
    await repo.saveLocal(expectedOwnerId: 'a', pageNumber: 15);
    remote.gate!.complete();
    expect((await sync).status, CheckpointSyncStatus.pending);
    expect((await repo.readLocal(expectedOwnerId: 'a'))!.pageNumber, 15);
  });
}
