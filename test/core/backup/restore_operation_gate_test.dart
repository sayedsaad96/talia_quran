import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/backup/restore_operation_gate.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

void main() {
  test(
    'a queued operation respects a recovery block imposed ahead of it',
    () async {
      final gate = RestoreOperationGate(const FixedRecordOwnerProvider('a'));
      final release = Completer<void>();
      var secondRan = false;
      final first = gate.run(
        expectedOwnerId: 'a',
        operation: () async {
          await release.future;
          gate.blockUntilRecovered('rollback_failed');
        },
      );
      final rejected = expectLater(
        gate.run(
          expectedOwnerId: 'a',
          operation: () async {
            secondRan = true;
          },
        ),
        throwsA(isA<RestoreBlockedException>()),
      );
      release.complete();
      await first;
      await rejected;
      expect(secondRan, isFalse);
    },
  );

  test('runs the operation and returns its value', () async {
    final gate = RestoreOperationGate(const FixedRecordOwnerProvider('a'));

    final value = await gate.run(
      expectedOwnerId: 'a',
      operation: () async => 42,
    );

    expect(value, 42);
    expect(gate.isRunning, isFalse);
  });

  test('rejects another owner without running the operation', () async {
    final gate = RestoreOperationGate(const FixedRecordOwnerProvider('a'));
    var ran = false;

    await expectLater(
      gate.run(
        expectedOwnerId: 'b',
        operation: () async {
          ran = true;
        },
      ),
      throwsA(isA<RestoreOwnerChangedException>()),
    );
    expect(ran, isFalse);
  });

  test('an owner switch while queued cancels the waiting run', () async {
    final owner = _MutableOwner('a');
    final gate = RestoreOperationGate(owner);
    final release = Completer<void>();
    final first = gate.run(
      expectedOwnerId: 'a',
      operation: () => release.future,
    );
    var secondRan = false;
    final second = gate.run(
      expectedOwnerId: 'a',
      operation: () async {
        secondRan = true;
      },
    );

    final secondRejected = expectLater(
      second,
      throwsA(isA<RestoreOwnerChangedException>()),
    );
    await Future<void>.delayed(Duration.zero);
    owner.currentOwnerId = 'b';
    release.complete();
    await first;

    await secondRejected;
    expect(secondRan, isFalse);
  });

  test('runs never overlap', () async {
    final gate = RestoreOperationGate(const FixedRecordOwnerProvider('a'));
    var active = 0;
    var maxActive = 0;

    Future<void> work() async {
      active++;
      maxActive = active > maxActive ? active : maxActive;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      active--;
    }

    await Future.wait([
      for (var i = 0; i < 4; i++)
        gate.run(expectedOwnerId: 'a', operation: work),
    ]);

    expect(maxActive, 1);
  });

  test('a failed run does not poison the queue', () async {
    final gate = RestoreOperationGate(const FixedRecordOwnerProvider('a'));

    await expectLater(
      gate.run<void>(
        expectedOwnerId: 'a',
        operation: () async => throw StateError('boom'),
      ),
      throwsStateError,
    );

    expect(
      await gate.run(expectedOwnerId: 'a', operation: () async => 'ok'),
      'ok',
    );
  });

  test('re-entering the gate fails fast instead of deadlocking', () async {
    final gate = RestoreOperationGate(const FixedRecordOwnerProvider('a'));

    await expectLater(
      gate.run(
        expectedOwnerId: 'a',
        operation: () =>
            gate.run(expectedOwnerId: 'a', operation: () async => 1),
      ),
      throwsA(isA<RestoreGateReentryException>()),
    );
  });

  test('isRunning is true only while an operation is active', () async {
    final gate = RestoreOperationGate(const FixedRecordOwnerProvider('a'));
    final release = Completer<void>();

    final run = gate.run(expectedOwnerId: 'a', operation: () => release.future);
    await Future<void>.delayed(Duration.zero);
    expect(gate.isRunning, isTrue);

    release.complete();
    await run;
    expect(gate.isRunning, isFalse);
  });

  test('a recovery block rejects restores until cleared', () async {
    final gate = RestoreOperationGate(const FixedRecordOwnerProvider('a'));
    gate.blockUntilRecovered('journal_unreadable');

    expect(gate.isBlocked, isTrue);
    await expectLater(
      gate.run(expectedOwnerId: 'a', operation: () async {}),
      throwsA(isA<RestoreBlockedException>()),
    );

    gate.clearRecoveryBlock();
    await gate.run(expectedOwnerId: 'a', operation: () async {});
  });
}
