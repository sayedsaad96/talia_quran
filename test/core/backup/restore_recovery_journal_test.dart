import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/backup/restore_recovery_journal.dart';
import 'package:talia_quran/core/security/encrypted_account_preferences_store.dart';

/// Simulated process death: thrown by [_FakeStore] when its write budget is
/// exhausted. Everything written before it stays durable.
class _Crash extends Error {}

class _FakeStore implements EncryptedAccountPreferencesStore {
  final Map<String, String> values = {};

  /// Writes allowed before the process "dies" (null = unlimited).
  int? writeBudget;
  int? deleteBudget;
  bool Function(String key)? failWrite;
  bool unreadable = false;
  bool deletesAreNoOps = false;
  int writes = 0;
  int maxValueBytes = 0;

  String _k(String owner, String key) => '$owner/$key';

  @override
  Future<String?> read(String ownerId, String key) async {
    if (unreadable) throw Exception('keystore unavailable');
    return values[_k(ownerId, key)];
  }

  @override
  Future<void> write(String ownerId, String key, String value) async {
    final budget = writeBudget;
    if (budget != null) {
      if (budget <= 0) throw _Crash();
      writeBudget = budget - 1;
    }
    if (failWrite?.call(key) ?? false) throw Exception('write failed: $key');
    writes++;
    final bytes = utf8.encode(value).length;
    if (bytes > maxValueBytes) maxValueBytes = bytes;
    values[_k(ownerId, key)] = value;
  }

  @override
  Future<void> delete(String ownerId, String key) async {
    if (deletesAreNoOps) return;
    final budget = deleteBudget;
    if (budget != null) {
      if (budget <= 0) throw _Crash();
      deleteBudget = budget - 1;
    }
    values.remove(_k(ownerId, key));
  }
}

const _owner = 'owner-a';

RestoreRecoveryJournal _journal(
  _FakeStore store, {
  int maxChunkBytes = 16 * 1024,
  int maxTotalBytes = 50 * 1024 * 1024,
}) => RestoreRecoveryJournal(
  store,
  maxChunkBytes: maxChunkBytes,
  maxTotalBytes: maxTotalBytes,
);

/// Records every rollback the journal asks for.
class _Rollbacks {
  final calls = <String>[];
  final snapshots = <String, String>{};
  Object? failWith;

  Map<String, RestoreRollback> get registry => {
    for (final part in const ['isar', 'prefs', 'bookmarks'])
      part: (owner, snapshot) async {
        if (failWith != null) throw failWith!;
        calls.add('$owner:$part');
        snapshots[part] = snapshot;
      },
  };
}

const _snapshots = {
  'isar': '{"reviews":[1,2,3]}',
  'prefs': '{"read_pages":"[1,2]"}',
  'bookmarks': '[]',
};

void main() {
  test(
    'worker admission remains closed until durable journal cleanup',
    () async {
      final store = _FakeStore();
      final journal = _journal(store);
      expect(await journal.isCleanForAdmission(), isTrue);
      final ticket = await journal.prepare(
        destinationOwner: _owner,
        snapshots: _snapshots,
      );
      expect(await journal.isCleanForAdmission(), isFalse);
      await journal.markCommitted(ticket);
      expect(await journal.isCleanForAdmission(), isFalse);
      await journal.complete(ticket);
      expect(await journal.isCleanForAdmission(), isTrue);
    },
  );
  test(
    'unreadable or malformed journal never admits workers or mutates it',
    () async {
      final store = _FakeStore()..unreadable = true;
      final journal = _journal(store);
      expect(await journal.isCleanForAdmission(), isFalse);
      store.unreadable = false;
      for (final marker in ['intent', 'manifest', 'state']) {
        store.values.clear();
        store.values['restore-journal.v1/$marker'] = 'corrupt';
        expect(await journal.isCleanForAdmission(), isFalse);
        expect(store.values.length, 1);
        expect(store.writes, 0);
      }
    },
  );
  test('UTF-8 boundaries leave no undiscoverable snapshot chunks', () async {
    final store = _FakeStore();
    final journal = _journal(store, maxChunkBytes: 4);
    final ticket = await journal.prepare(
      destinationOwner: _owner,
      snapshots: {'prefs': '€€€€'},
    );
    await journal.markCommitted(ticket);
    await journal.complete(ticket);
    expect(store.values, isEmpty);
  });

  test('death after each cleanup delete can finish on restart', () async {
    for (var budget = 0; budget < 7; budget++) {
      final store = _FakeStore();
      final journal = _journal(store);
      final ticket = await journal.prepare(
        destinationOwner: _owner,
        snapshots: _snapshots,
      );
      await journal.markCommitted(ticket);
      store.deleteBudget = budget;
      try {
        await journal.complete(ticket);
      } on _Crash {
        /* A new journal below represents the restarted process. */
      }
      store.deleteBudget = null;
      final rollbacks = _Rollbacks();
      final recovery = await _journal(store).recoverBeforeReady(
        activeOwnerId: _owner,
        rollbacks: rollbacks.registry,
      );
      expect(recovery.isBlocked, isFalse, reason: 'delete budget $budget');
      expect(rollbacks.calls, isEmpty);
      expect(store.values, isEmpty);
    }
  });

  test('a committed decision can never enter rollback', () async {
    final store = _FakeStore();
    final journal = _journal(store);
    final ticket = await journal.prepare(
      destinationOwner: _owner,
      snapshots: _snapshots,
    );
    await journal.markCommitted(ticket);
    final rollbacks = _Rollbacks();
    await expectLater(
      journal.rollback(ticket, rollbacks.registry),
      throwsStateError,
    );
    expect(rollbacks.calls, isEmpty);
    final result = await _journal(
      store,
    ).recoverBeforeReady(activeOwnerId: _owner, rollbacks: rollbacks.registry);
    expect(result.status, RestoreRecoveryStatus.completed);
    expect(rollbacks.calls, isEmpty);
  });

  group('prepare / commit / complete', () {
    test('a full successful restore leaves no journal state behind', () async {
      final store = _FakeStore();
      final journal = _journal(store);

      final ticket = await journal.prepare(
        destinationOwner: _owner,
        snapshots: _snapshots,
      );
      expect(store.values, isNotEmpty);
      await journal.markCommitted(ticket);
      await journal.complete(ticket);

      expect(store.values, isEmpty);
    });

    test('prepare refuses to start while another journal exists', () async {
      final store = _FakeStore();
      final journal = _journal(store);
      await journal.prepare(destinationOwner: _owner, snapshots: _snapshots);

      await expectLater(
        journal.prepare(destinationOwner: _owner, snapshots: _snapshots),
        throwsA(isA<RestoreJournalRejected>()),
      );
    });

    test('splits snapshots into chunks of at most 16 KiB UTF-8', () async {
      final store = _FakeStore();
      final big = List.filled(30000, 'آية').join();
      final journal = _journal(store);

      await journal.prepare(
        destinationOwner: _owner,
        snapshots: {'isar': big, 'prefs': '{}', 'bookmarks': '[]'},
      );

      expect(store.maxValueBytes, lessThanOrEqualTo(16 * 1024));
      final rollbacks = _Rollbacks();
      final result = await _journal(store).recoverBeforeReady(
        activeOwnerId: _owner,
        rollbacks: rollbacks.registry,
      );
      expect(result.status, RestoreRecoveryStatus.rolledBack);
      expect(rollbacks.snapshots['isar'], big);
    });

    test(
      'rejects a snapshot set over the capacity cap before any write',
      () async {
        final store = _FakeStore();
        final journal = _journal(store, maxTotalBytes: 100);

        await expectLater(
          journal.prepare(
            destinationOwner: _owner,
            snapshots: {'isar': 'x' * 101},
          ),
          throwsA(
            isA<RestoreJournalRejected>().having(
              (e) => e.reason,
              'reason',
              RestoreJournalRejection.capacity,
            ),
          ),
        );
        expect(store.writes, 0);
        expect(store.values, isEmpty);
      },
    );

    test('failure storing the last chunk rejects and cleans up', () async {
      final store = _FakeStore();
      store.failWrite = (key) => key.endsWith('.1');
      final journal = _journal(store, maxChunkBytes: 10);

      await expectLater(
        journal.prepare(
          destinationOwner: _owner,
          snapshots: {'isar': 'abcdefghijklmnopqrst', 'prefs': '{}'},
        ),
        throwsA(isA<RestoreJournalRejected>()),
      );

      expect(store.values, isEmpty);
    });

    test('an unreadable keystore rejects prepare', () async {
      final store = _FakeStore()..unreadable = true;

      await expectLater(
        _journal(
          store,
        ).prepare(destinationOwner: _owner, snapshots: _snapshots),
        throwsA(isA<RestoreJournalRejected>()),
      );
    });
  });

  group('recovery after process death', () {
    test('death at every write of prepare never triggers a rollback', () async {
      final probe = _FakeStore();
      await _journal(
        probe,
      ).prepare(destinationOwner: _owner, snapshots: _snapshots);
      final totalWrites = probe.writes;

      for (var budget = 0; budget < totalWrites; budget++) {
        final store = _FakeStore()..writeBudget = budget;
        await expectLater(
          _journal(
            store,
          ).prepare(destinationOwner: _owner, snapshots: _snapshots),
          throwsA(anything),
          reason: 'budget $budget',
        );
        store.writeBudget = null;

        final rollbacks = _Rollbacks();
        final result = await _journal(store).recoverBeforeReady(
          activeOwnerId: _owner,
          rollbacks: rollbacks.registry,
        );

        expect(rollbacks.calls, isEmpty, reason: 'budget $budget');
        expect(
          result.status,
          anyOf(RestoreRecoveryStatus.clean, RestoreRecoveryStatus.discarded),
          reason: 'budget $budget',
        );
        expect(store.values, isEmpty, reason: 'budget $budget');
      }
    });

    test('a prepared journal rolls every part back and cleans up', () async {
      final store = _FakeStore();
      await _journal(
        store,
      ).prepare(destinationOwner: _owner, snapshots: _snapshots);

      final rollbacks = _Rollbacks();
      final result = await _journal(store).recoverBeforeReady(
        activeOwnerId: _owner,
        rollbacks: rollbacks.registry,
      );

      expect(result.status, RestoreRecoveryStatus.rolledBack);
      expect(rollbacks.calls, [
        'owner-a:isar',
        'owner-a:prefs',
        'owner-a:bookmarks',
      ]);
      expect(rollbacks.snapshots, _snapshots);
      expect(store.values, isEmpty);
    });

    test(
      'a committed journal only finishes cleanup, never rolls back',
      () async {
        final store = _FakeStore();
        final journal = _journal(store);
        final ticket = await journal.prepare(
          destinationOwner: _owner,
          snapshots: _snapshots,
        );
        await journal.markCommitted(ticket);

        final rollbacks = _Rollbacks();
        final result = await _journal(store).recoverBeforeReady(
          activeOwnerId: _owner,
          rollbacks: rollbacks.registry,
        );

        expect(result.status, RestoreRecoveryStatus.completed);
        expect(rollbacks.calls, isEmpty);
        expect(store.values, isEmpty);
      },
    );

    test('no journal is a clean start', () async {
      final result = await _journal(_FakeStore()).recoverBeforeReady(
        activeOwnerId: _owner,
        rollbacks: _Rollbacks().registry,
      );

      expect(result.status, RestoreRecoveryStatus.clean);
    });

    test('death in the middle of a rollback is retried idempotently', () async {
      final store = _FakeStore();
      await _journal(
        store,
      ).prepare(destinationOwner: _owner, snapshots: _snapshots);
      final failing = _Rollbacks()..failWith = Exception('disk full');

      final first = await _journal(
        store,
      ).recoverBeforeReady(activeOwnerId: _owner, rollbacks: failing.registry);

      expect(first.status, RestoreRecoveryStatus.blocked);
      expect(store.values, isNotEmpty);

      final retry = _Rollbacks();
      final second = await _journal(
        store,
      ).recoverBeforeReady(activeOwnerId: _owner, rollbacks: retry.registry);
      expect(second.status, RestoreRecoveryStatus.rolledBack);
      expect(retry.snapshots, _snapshots);
      expect(store.values, isEmpty);
    });

    test(
      'death at every write after the rollback finished stays safe',
      () async {
        final probe = _FakeStore();
        await _journal(
          probe,
        ).prepare(destinationOwner: _owner, snapshots: _snapshots);
        final prepared = Map<String, String>.of(probe.values);

        for (var budget = 0; budget < 3; budget++) {
          final store = _FakeStore()..values.addAll(prepared);
          store.writeBudget = budget;
          await _journal(store)
              .recoverBeforeReady(
                activeOwnerId: _owner,
                rollbacks: _Rollbacks().registry,
              )
              .then<void>((_) {}, onError: (_) {});
          store.writeBudget = null;

          final result = await _journal(store).recoverBeforeReady(
            activeOwnerId: _owner,
            rollbacks: _Rollbacks().registry,
          );

          expect(
            result.status,
            anyOf(
              RestoreRecoveryStatus.rolledBack,
              RestoreRecoveryStatus.completed,
              RestoreRecoveryStatus.clean,
            ),
            reason: 'budget $budget',
          );
          expect(store.values, isEmpty, reason: 'budget $budget');
        }
      },
    );

    test(
      'cleanup that did not really delete stays pending and retries',
      () async {
        final store = _FakeStore();
        final journal = _journal(store);
        final ticket = await journal.prepare(
          destinationOwner: _owner,
          snapshots: _snapshots,
        );
        await journal.markCommitted(ticket);
        store.deletesAreNoOps = true;

        await expectLater(
          journal.complete(ticket),
          throwsA(isA<RestoreJournalCleanupPending>()),
        );
        expect(store.values, isNotEmpty);

        store.deletesAreNoOps = false;
        final rollbacks = _Rollbacks();
        final result = await _journal(store).recoverBeforeReady(
          activeOwnerId: _owner,
          rollbacks: rollbacks.registry,
        );

        expect(result.status, RestoreRecoveryStatus.completed);
        expect(rollbacks.calls, isEmpty);
        expect(store.values, isEmpty);
      },
    );

    test('an unreachable keystore keeps recovery blocked', () async {
      final store = _FakeStore();
      await _journal(
        store,
      ).prepare(destinationOwner: _owner, snapshots: _snapshots);
      store.unreadable = true;

      final rollbacks = _Rollbacks();
      final result = await _journal(store).recoverBeforeReady(
        activeOwnerId: _owner,
        rollbacks: rollbacks.registry,
      );

      expect(result.status, RestoreRecoveryStatus.blocked);
      expect(rollbacks.calls, isEmpty);
    });

    test(
      'a corrupt snapshot chunk blocks instead of restoring garbage',
      () async {
        final store = _FakeStore();
        await _journal(
          store,
        ).prepare(destinationOwner: _owner, snapshots: _snapshots);
        final chunkKey = store.values.keys.firstWhere(
          (k) => k.contains('part.'),
        );
        store.values[chunkKey] = 'tampered';

        final rollbacks = _Rollbacks();
        final result = await _journal(store).recoverBeforeReady(
          activeOwnerId: _owner,
          rollbacks: rollbacks.registry,
        );

        expect(result.status, RestoreRecoveryStatus.blocked);
        expect(rollbacks.calls, isEmpty);
      },
    );

    test('a truncated manifest with a published state blocks', () async {
      final store = _FakeStore();
      await _journal(
        store,
      ).prepare(destinationOwner: _owner, snapshots: _snapshots);
      final key = store.values.keys.firstWhere((k) => k.endsWith('/manifest'));
      store.values[key] = store.values[key]!.substring(0, 20);

      final rollbacks = _Rollbacks();
      final result = await _journal(store).recoverBeforeReady(
        activeOwnerId: _owner,
        rollbacks: rollbacks.registry,
      );

      expect(result.status, RestoreRecoveryStatus.blocked);
      expect(rollbacks.calls, isEmpty);
    });

    test(
      'a truncated manifest without a state is an orphan, not a restore',
      () async {
        final store = _FakeStore();
        await _journal(
          store,
        ).prepare(destinationOwner: _owner, snapshots: _snapshots);
        store.values.removeWhere((k, _) => k.endsWith('/state'));
        final key = store.values.keys.firstWhere(
          (k) => k.endsWith('/manifest'),
        );
        store.values[key] = store.values[key]!.substring(0, 20);

        final rollbacks = _Rollbacks();
        final result = await _journal(store).recoverBeforeReady(
          activeOwnerId: _owner,
          rollbacks: rollbacks.registry,
        );

        expect(result.status, RestoreRecoveryStatus.discarded);
        expect(rollbacks.calls, isEmpty);
        expect(store.values, isEmpty);
      },
    );

    test('never rolls A back into a different active account', () async {
      final store = _FakeStore();
      await _journal(
        store,
      ).prepare(destinationOwner: 'owner-a', snapshots: _snapshots);

      final rollbacks = _Rollbacks();
      final result = await _journal(store).recoverBeforeReady(
        activeOwnerId: 'owner-b',
        rollbacks: rollbacks.registry,
      );

      expect(result.status, RestoreRecoveryStatus.blocked);
      expect(rollbacks.calls, isEmpty);
      expect(store.values, isNotEmpty);
    });

    test('a part the registry does not know blocks recovery', () async {
      final store = _FakeStore();
      await _journal(store).prepare(
        destinationOwner: _owner,
        snapshots: {..._snapshots, 'mystery': '{}'},
      );

      final rollbacks = _Rollbacks();
      final result = await _journal(store).recoverBeforeReady(
        activeOwnerId: _owner,
        rollbacks: rollbacks.registry,
      );

      expect(result.status, RestoreRecoveryStatus.blocked);
      expect(rollbacks.calls, isEmpty);
    });
  });

  group('account deletion wins', () {
    test('an aborted journal is cleaned without restoring any data', () async {
      final store = _FakeStore();
      await _journal(
        store,
      ).prepare(destinationOwner: _owner, snapshots: _snapshots);

      await _journal(store).abortForOwner(_owner);

      expect(store.values, isEmpty);
      final rollbacks = _Rollbacks();
      final result = await _journal(store).recoverBeforeReady(
        activeOwnerId: _owner,
        rollbacks: rollbacks.registry,
      );
      expect(result.status, RestoreRecoveryStatus.clean);
      expect(rollbacks.calls, isEmpty);
    });

    test('abort decision survives a death before cleanup finishes', () async {
      final store = _FakeStore();
      await _journal(
        store,
      ).prepare(destinationOwner: _owner, snapshots: _snapshots);
      store.deletesAreNoOps = true;

      await _journal(
        store,
      ).abortForOwner(_owner).then<void>((_) {}, onError: (_) {});
      store.deletesAreNoOps = false;

      final rollbacks = _Rollbacks();
      final result = await _journal(store).recoverBeforeReady(
        activeOwnerId: _owner,
        rollbacks: rollbacks.registry,
      );

      expect(rollbacks.calls, isEmpty);
      expect(result.status, RestoreRecoveryStatus.discarded);
      expect(store.values, isEmpty);
    });

    test('another owner\'s journal is left alone', () async {
      final store = _FakeStore();
      await _journal(
        store,
      ).prepare(destinationOwner: 'owner-a', snapshots: _snapshots);

      await _journal(store).abortForOwner('owner-b');

      expect(store.values, isNotEmpty);
    });
  });
}
