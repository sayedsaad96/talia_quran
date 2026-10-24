import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_remote.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_repository_impl.dart';
import 'package:talia_quran/features/group_khatmah/domain/entities/group_khatmah.dart';

import 'group_khatmah_test_support.dart';

void main() {
  late SharedPreferences prefs;
  late MutableOwner owner;
  late MutableEnvironment environment;
  late FakeRemote remote;
  late GroupKhatmahRepositoryImpl repository;
  var operationSequence = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = MutableOwner(ownerA);
    AccountDataBarrier.forPreferences(prefs).owner = owner;
    environment = MutableEnvironment();
    remote = FakeRemote();
    operationSequence = 0;
    repository = GroupKhatmahRepositoryImpl(
      preferences: prefs,
      owner: owner,
      remote: remote,
      wake: FakeWake(),
      environment: environment,
      operationId: () => operationSequence++ == 0
          ? operation1
          : '00000000-0000-4000-8000-${operationSequence.toString().padLeft(12, '0')}',
    );
    addTearDown(() async {
      await repository.dispose();
      await environment.dispose();
    });
  });

  test(
    'refresh preserves group joined while missing member is rechecked',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      await repository.refreshMine();
      final recheck = Completer<void>();
      final release = Completer<void>();
      remote.onPage = (_, _) async =>
          GroupKhatmahPage(groups: const [], nextCursor: null);
      remote.onGroup = (_, id) async {
        if (id == groupA) {
          recheck.complete();
          await release.future;
          return null;
        }
        return remote.groups[id];
      };
      final refresh = repository.refreshMine();
      await recheck.future;
      remote.groups[groupB] = fixture(groupB, ownerA, epochB);
      remote.onRpc = (call) async => {
        'applied': true,
        'code': 'joined',
        'operation_id': call.args['p_operation_id'],
        'group_id': groupB,
        'group_version': 2,
      };
      expect((await repository.join('ABC234', 'Reader')).isRight(), isTrue);
      release.complete();
      await refresh;
      expect(
        (await repository.watchMine().first).map((g) => g.id),
        contains(groupB),
      );
    },
  );

  test(
    'confirmed membership absence wins over a delayed prior claim acknowledgement',
    () async {
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        firstStatus: GroupPartStatus.open,
        firstVersion: 1,
      );
      await repository.refreshMine();
      final rpcStarted = Completer<void>();
      final acknowledge = Completer<void>();
      remote.onRpc = (call) async {
        rpcStarted.complete();
        await acknowledge.future;
        return {
          'applied': true,
          'code': 'claimed',
          'group_id': groupA,
          'group_version': 3,
          'part_version': 2,
        };
      };
      final claim = repository.claim(groupA, 1);
      await rpcStarted.future;
      final recheckStarted = Completer<void>();
      final absence = Completer<void>();
      remote.onPage = (_, _) async =>
          GroupKhatmahPage(groups: const [], nextCursor: null);
      remote.onGroup = (_, _) async {
        recheckStarted.complete();
        await absence.future;
        return null;
      };
      final refresh = repository.refreshMine();
      await recheckStarted.future;
      acknowledge.complete();
      expect((await claim).isRight(), isTrue);
      absence.complete();
      await refresh;
      expect(await repository.watchMine().first, isEmpty);
    },
  );

  test(
    'late claim acknowledgement cannot restore a purged membership',
    () async {
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        firstStatus: GroupPartStatus.open,
        firstVersion: 1,
      );
      await repository.refreshMine();
      final started = Completer<void>();
      final releaseAck = Completer<void>();
      remote.onRpc = (_) async {
        started.complete();
        await releaseAck.future;
        return {
          'applied': true,
          'code': 'claimed',
          'group_id': groupA,
          'group_version': 3,
          'part_version': 2,
        };
      };
      final claim = repository.claim(groupA, 1);
      await started.future;
      remote.groups.clear();
      expect((await repository.refreshMine()).isRight(), isTrue);
      expect(await repository.watchMine().first, isEmpty);
      releaseAck.complete();
      expect((await claim).isLeft(), isTrue);
      expect(await repository.watchMine().first, isEmpty);
    },
  );

  test(
    'delayed conflict snapshot cannot restore a purged membership',
    () async {
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        firstStatus: GroupPartStatus.open,
        firstVersion: 1,
      );
      await repository.refreshMine();
      remote.onRpc = (_) async => {'applied': false, 'code': 'conflict'};
      final snapshotStarted = Completer<void>();
      final releaseSnapshot = Completer<void>();
      var lookups = 0;
      remote.onGroup = (_, _) async {
        lookups++;
        if (lookups == 1) return remote.groups[groupA];
        if (lookups == 2) {
          final old = remote.groups[groupA];
          snapshotStarted.complete();
          await releaseSnapshot.future;
          return old;
        }
        return null;
      };
      final claim = repository.claim(groupA, 1);
      await snapshotStarted.future;
      remote.groups.clear();
      await repository.refreshMine();
      releaseSnapshot.complete();
      await claim;
      expect(await repository.watchMine().first, isEmpty);
    },
  );

  test(
    'late claim acknowledgement cannot overwrite a rejoined membership',
    () async {
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        firstStatus: GroupPartStatus.open,
        firstVersion: 1,
      );
      await repository.refreshMine();
      final started = Completer<void>();
      final releaseAck = Completer<void>();
      remote.onRpc = (_) async {
        started.complete();
        await releaseAck.future;
        return {
          'applied': true,
          'code': 'claimed',
          'group_id': groupA,
          'group_version': 3,
          'part_version': 2,
        };
      };
      final claim = repository.claim(groupA, 1);
      await started.future;
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochB,
      ).copyWith(version: 4);
      await repository.refreshMine();
      releaseAck.complete();
      expect((await claim).isLeft(), isTrue);
      expect(
        (await repository.watchMine().first).single.membershipEpoch,
        epochB,
      );
    },
  );

  test(
    'old pull cannot restore a group joined and left after its empty baseline',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      var first = true;
      remote.onPage = (_, _) async {
        if (first) {
          first = false;
          started.complete();
          await release.future;
          return GroupKhatmahPage(
            groups: [fixture(groupA, ownerA, epochA)],
            nextCursor: null,
          );
        }
        return GroupKhatmahPage(groups: const [], nextCursor: null);
      };
      final refresh = repository.refreshMine();
      await started.future;
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      remote.onRpc = (call) async => {
        'applied': true,
        'code': 'joined',
        'group_id': groupA,
        'group_version': 2,
        'membership_epoch': epochA,
      };
      expect((await repository.join('ABC234', 'Reader')).isRight(), isTrue);
      expect((await repository.leave(groupA)).isRight(), isTrue);
      release.complete();
      await refresh;
      expect(await repository.watchMine().first, isEmpty);
    },
  );

  for (final outcome in ['left', 'not_member', 'gone']) {
    test(
      'old $outcome response preserves rejoined membership and new completion',
      () async {
        remote.groups[groupA] = fixture(
          groupA,
          ownerA,
          epochA,
          groupOwner: ownerB,
        );
        await repository.refreshMine();
        final started = Completer<void>();
        final release = Completer<void>();
        remote.onRpc = (call) async {
          if (call.function == 'leave_group_khatmah') {
            started.complete();
            await release.future;
            return {
              'applied': outcome == 'left',
              'code': outcome,
              'group_id': groupA,
            };
          }
          return {
            'applied': true,
            'code': 'joined',
            'group_id': groupA,
            'group_version': 4,
            'membership_epoch': epochB,
          };
        };
        final leaving = repository.leave(groupA);
        await started.future;
        remote.groups[groupA] = fixture(
          groupA,
          ownerA,
          epochB,
          groupOwner: ownerB,
        ).copyWith(version: 4);
        expect((await repository.join('ABC234', 'Reader')).isRight(), isTrue);
        expect((await repository.completeLocally(groupA, 1)).isRight(), isTrue);
        release.complete();
        await leaving;
        final group = (await repository.watchMine().first).single;
        expect(group.membershipEpoch, epochB);
        expect(group.part(1)!.isCompletionPending, isTrue);
        expect(await repository.hasPending(), isTrue);
      },
    );
  }

  test('stale refresh does not restore a concurrently left group', () async {
    remote.groups[groupA] = fixture(groupA, ownerA, epochA);
    await repository.refreshMine();
    final pageStarted = Completer<void>();
    final release = Completer<void>();
    var firstPage = true;
    remote.onPage = (_, _) async {
      if (firstPage) {
        firstPage = false;
        pageStarted.complete();
        await release.future;
      }
      return GroupKhatmahPage(
        groups: [fixture(groupA, ownerA, epochA)],
        nextCursor: null,
      );
    };
    final refresh = repository.refreshMine();
    await pageStarted.future;
    expect((await repository.leave(groupA)).isRight(), isTrue);
    release.complete();
    await refresh;
    expect(await repository.watchMine().first, isEmpty);
  });

  test(
    'lost leave acknowledgement replay purges group without refresh',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      await repository.refreshMine();
      var calls = 0;
      remote.onRpc = (call) async {
        calls++;
        if (calls == 1) throw TimeoutException('lost leave response');
        return {
          'applied': true,
          'code': 'left',
          'operation_id': call.args['p_operation_id'],
          'group_id': groupA,
        };
      };
      expect((await repository.leave(groupA)).isLeft(), isTrue);
      expect((await repository.watchMine().first).single.id, groupA);
      await repository.dispose();
      repository = GroupKhatmahRepositoryImpl(
        preferences: prefs,
        owner: owner,
        remote: remote,
        wake: FakeWake(),
        environment: environment,
        operationId: () => operation2,
        clock: () => DateTime.now().add(const Duration(hours: 1)),
      );
      remote.onPage = (_, _) async => throw TimeoutException('refresh offline');
      expect((await repository.refreshMine()).isLeft(), isTrue);
      await repository.flushPending();
      expect(calls, 2);
      expect(await repository.watchMine().first, isEmpty);
      expect(await repository.hasPending(), isFalse);
    },
  );

  test(
    'part claim with group version gap reads interleaved other part',
    () async {
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        groupVersion: 1,
        firstStatus: GroupPartStatus.open,
        firstVersion: 1,
      );
      await repository.refreshMine();
      remote.onRpc = (call) async {
        remote.groups[groupA] = fixture(
          groupA,
          ownerA,
          epochA,
          groupVersion: 3,
          firstStatus: GroupPartStatus.claimed,
          firstVersion: 2,
          secondStatus: GroupPartStatus.completed,
          secondVersion: 2,
        );
        return {
          'applied': true,
          'code': 'claimed',
          'operation_id': call.args['p_operation_id'],
          'group_id': groupA,
          'group_version': 3,
          'part_version': 2,
        };
      };
      expect((await repository.claim(groupA, 1)).isRight(), isTrue);
      final group = (await repository.watchMine().first).single;
      expect(group.version, 3);
      expect(group.part(2)?.status, GroupPartStatus.completed);
    },
  );

  test(
    'completion with group version gap reads interleaved other part',
    () async {
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        groupVersion: 1,
        firstVersion: 1,
      );
      await repository.refreshMine();
      await repository.completeLocally(groupA, 1);
      remote.onRpc = (call) async {
        remote.groups[groupA] = fixture(
          groupA,
          ownerA,
          epochA,
          groupVersion: 3,
          firstStatus: GroupPartStatus.completed,
          firstVersion: 2,
          secondStatus: GroupPartStatus.claimed,
          secondVersion: 2,
        );
        return {
          'applied': true,
          'code': 'completed',
          'operation_id': call.args['p_operation_id'],
          'group_id': groupA,
          'group_version': 3,
          'part_version': 2,
        };
      };
      await repository.flushPending();
      final group = (await repository.watchMine().first).single;
      expect(group.version, 3);
      expect(group.part(2)?.status, GroupPartStatus.claimed);
    },
  );
}
