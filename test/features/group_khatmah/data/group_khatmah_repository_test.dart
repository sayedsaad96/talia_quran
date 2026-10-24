import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_remote.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_repository_impl.dart';
import 'package:talia_quran/features/group_khatmah/domain/entities/group_khatmah.dart';
import 'package:talia_quran/features/group_khatmah/domain/repositories/group_khatmah_repository.dart';
import 'group_khatmah_test_support.dart';

void main() {
  late SharedPreferences prefs;
  late MutableOwner owner;
  late MutableEnvironment environment;
  late FakeRemote remote;
  late FakeWake wake;
  late GroupKhatmahRepositoryImpl repository;
  late int nextId;
  late DateTime currentTime;

  GroupKhatmahRepositoryImpl build() => GroupKhatmahRepositoryImpl(
    preferences: prefs,
    owner: owner,
    remote: remote,
    wake: wake,
    environment: environment,
    operationId: () => [operation1, operation2][nextId++],
    clock: () => currentTime,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = MutableOwner(ownerA);
    AccountDataBarrier.forPreferences(prefs).owner = owner;
    environment = MutableEnvironment();
    remote = FakeRemote();
    wake = FakeWake();
    nextId = 0;
    currentTime = DateTime.utc(2026, 10, 23);
    repository = build();
    addTearDown(() async {
      await repository.dispose();
      await environment.dispose();
    });
  });

  test('offline claim writes no intent or optimistic state', () async {
    environment.isOnline = false;
    final result = await repository.claim(groupA, 1);
    expect(result.fold((f) => f is NetworkFailure, (_) => false), isTrue);
    expect(remote.calls, isEmpty);
    expect(
      prefs.getKeys().where((k) => k.startsWith('group_khatmah_cache_v1|')),
      isEmpty,
    );
    expect(wake.pushes, isEmpty);
  });

  test('online hint with failed preflight writes no create intent', () async {
    remote.onPage = (_, _) async => throw TimeoutException('offline');
    final result = await repository.create('Shared reading', 'Reader');
    expect(result.fold((f) => f is NetworkFailure, (_) => false), isTrue);
    expect(remote.calls, isEmpty);
    expect(prefs.getString('group_khatmah_cache_v1|$ownerA'), isNull);
  });

  test('failed group preflight writes no claim intent', () async {
    remote.groups[groupA] = fixture(
      groupA,
      ownerA,
      epochA,
      firstStatus: GroupPartStatus.open,
      firstVersion: 1,
    );
    await repository.refreshMine();
    final before = prefs.getString('group_khatmah_cache_v1|$ownerA');
    remote.onGroup = (_, _) async => throw TimeoutException('offline');
    final result = await repository.claim(groupA, 1);
    expect(result.fold((f) => f is NetworkFailure, (_) => false), isTrue);
    expect(remote.calls, isEmpty);
    expect(prefs.getString('group_khatmah_cache_v1|$ownerA'), before);
  });

  test(
    'create journals operation ID before RPC and retries same ID after lost ack',
    () async {
      var attempts = 0;
      remote.onRpc = (call) async {
        attempts++;
        expect(call.function, 'create_group_khatmah');
        expect(call.args['p_operation_id'], operation1);
        final raw = prefs.getString('group_khatmah_cache_v1|$ownerA');
        expect(raw, contains(operation1));
        expect(wake.pushes, contains(ownerA));
        if (attempts == 1) throw TimeoutException('lost response');
        remote.groups[groupA] = fixture(groupA, ownerA, epochA);
        return {
          'applied': true,
          'code': 'created',
          'operation_id': operation1,
          'group_id': groupA,
          'group_version': 1,
          'membership_epoch': epochA,
          'invite_code': 'ABC234',
        };
      };
      final first = await repository.create('Shared reading', 'Reader');
      expect(first.isLeft(), isTrue);
      expect(await repository.hasPending(), isTrue);

      // A new repository instance must drain the same durable intent.
      currentTime = currentTime.add(const Duration(hours: 2));
      await repository.dispose();
      repository = build();
      await repository.flushPending();
      expect(attempts, 2);
      expect(await repository.hasPending(), isFalse);
    },
  );

  test('join journals its operation ID before the invitation RPC', () async {
    remote.onRpc = (call) async {
      expect(call.function, 'join_group_khatmah');
      expect(call.args['p_operation_id'], operation1);
      expect(
        prefs.getString('group_khatmah_cache_v1|$ownerA'),
        contains(operation1),
      );
      return {
        'applied': true,
        'code': 'joined',
        'operation_id': operation1,
        'group_id': groupA,
        'group_version': 2,
        'membership_epoch': epochA,
      };
    };
    await repository.join('ABC234', 'Reader');
    expect(remote.calls.length, 1);
  });

  for (final action in ['claim', 'release', 'leave']) {
    test('$action journals an operation ID before the network call', () async {
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        firstStatus: action == 'claim'
            ? GroupPartStatus.open
            : GroupPartStatus.claimed,
        firstVersion: action == 'claim' ? 1 : 2,
      );
      await repository.refreshMine();
      remote.onRpc = (call) async {
        expect(call.args['p_operation_id'], operation1);
        expect(
          prefs.getString('group_khatmah_cache_v1|$ownerA'),
          contains(operation1),
        );
        return {
          'applied': true,
          'code': action == 'leave'
              ? 'left'
              : action == 'claim'
              ? 'claimed'
              : 'released',
          'operation_id': operation1,
          'group_id': groupA,
          'group_version': 3,
          'part_version': 3,
          'membership_epoch': epochA,
          'juz': 1,
        };
      };
      if (action == 'claim') await repository.claim(groupA, 1);
      if (action == 'release') await repository.release(groupA, 1);
      if (action == 'leave') await repository.leave(groupA);
      expect(
        remote.calls.single.function,
        action == 'leave' ? 'leave_group_khatmah' : '${action}_group_part',
      );
    });
  }

  test(
    'offline completion keeps confirmed claim and exact CAS inputs through restart',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      expect((await repository.refreshMine()).isRight(), isTrue);
      wake.pushes.clear();
      environment.isOnline = false;
      final saved = await repository.completeLocally(groupA, 1);
      expect(saved.isRight(), isTrue);
      expect(await repository.hasPending(), isTrue);
      expect(wake.pushes, [ownerA]);

      await repository.dispose();
      repository = build();
      environment.isOnline = true;
      await repository.flushPending();
      final call = remote.calls.single;
      expect(call.function, 'complete_group_part');
      expect(call.args['p_group_id'], groupA);
      expect(call.args['p_juz'], 1);
      expect(call.args['p_expected_version'], 2);
      expect(call.args['p_membership_epoch'], epochA);
      expect(call.args['p_operation_id'], operation1);
      expect(await repository.hasPending(), isFalse);
    },
  );

  test(
    'terminal not_member clears only its group and leaves other work runnable',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      remote.groups[groupB] = fixture(groupB, ownerA, epochB);
      await repository.refreshMine();
      environment.isOnline = false;
      await repository.completeLocally(groupA, 1);
      await repository.completeLocally(groupB, 1);
      environment.isOnline = true;
      remote.onRpc = (call) async {
        if (call.args['p_group_id'] == groupA) {
          return {'applied': false, 'code': 'not_member'};
        }
        return {
          'applied': true,
          'code': 'completed',
          'operation_id': call.args['p_operation_id'],
          'group_id': groupB,
          'group_version': 3,
          'part_version': 3,
          'juz': 1,
        };
      };
      await repository.flushPending();
      expect(await repository.hasPending(), isFalse);
      final seen = await repository.watchMine().first;
      expect(seen.map((g) => g.id), contains(groupB));
      expect(seen.map((g) => g.id), isNot(contains(groupA)));
      expect(remote.calls.length, 2);
    },
  );

  test(
    'claim conflict refreshes authoritative part without rebasing the CAS',
    () async {
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        firstStatus: GroupPartStatus.open,
        firstVersion: 1,
      );
      await repository.refreshMine();
      remote.onRpc = (call) async {
        remote.groups[groupA] = fixture(groupA, ownerA, epochA);
        return {
          'applied': false,
          'code': 'conflict',
          'operation_id': call.args['p_operation_id'],
          'group_version': 2,
          'part': {
            'group_id': groupA,
            'juz': 1,
            'status': 'claimed',
            'claimed_by': ownerB,
            'claim_epoch': epochB,
            'version': 2,
            'updated_at': '2026-10-23T00:00:00Z',
          },
        };
      };
      final result = await repository.claim(groupA, 1);
      expect(
        result.fold((f) => f is GroupPartConflictFailure, (_) => false),
        isTrue,
      );
      expect(remote.calls.single.args['p_expected_version'], 1);
      final part = (await repository.watchMine().first).single.parts.first;
      expect(part.status, GroupPartStatus.claimed);
      expect(part.version, 2);
    },
  );

  test('partial membership page failure cannot erase a cached group', () async {
    remote.groups[groupA] = fixture(groupA, ownerA, epochA);
    await repository.refreshMine();
    remote.onPage = (_, cursor) async {
      if (cursor == null) {
        return GroupKhatmahPage(groups: const [], nextCursor: 'page-2');
      }
      throw TimeoutException('partial list');
    };
    final result = await repository.refreshMine();
    expect(result.isLeft(), isTrue);
    expect(
      (await repository.watchMine().first).map((g) => g.id),
      contains(groupA),
    );
  });

  test(
    'complete membership absence revalidates missing group before purge',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      await repository.refreshMine();
      remote.onPage = (_, _) async =>
          GroupKhatmahPage(groups: const [], nextCursor: null);
      remote.onGroup = (_, _) async => null;
      await repository.refreshMine();
      expect(remote.groupLookups, contains(groupA));
      expect(await repository.watchMine().first, isEmpty);
    },
  );

  test(
    'revalidation retains a member omitted by a drifting page boundary',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      await repository.refreshMine();
      remote.onPage = (_, _) async =>
          GroupKhatmahPage(groups: const [], nextCursor: null);
      await repository.refreshMine();
      expect(remote.groupLookups, contains(groupA));
      expect(
        (await repository.watchMine().first).map((g) => g.id),
        contains(groupA),
      );
    },
  );

  test(
    'offline overlay is discarded when server releases the claimed part',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      await repository.refreshMine();
      environment.isOnline = false;
      await repository.completeLocally(groupA, 1);
      environment.isOnline = true;
      await repository.refreshMine();
      var part = (await repository.watchMine().first).single.parts.first;
      expect(part.isCompletionPending, isTrue);

      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        firstStatus: GroupPartStatus.open,
        firstVersion: 3,
      );
      await repository.refreshMine();
      part = (await repository.watchMine().first).single.parts.first;
      expect(part.status, GroupPartStatus.open);
      expect(part.isCompletionPending, isFalse);
      expect(await repository.hasPending(), isFalse);
    },
  );

  test(
    'dead letter in A does not spend the retry budget of later B work',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      remote.groups[groupB] = fixture(groupB, ownerA, epochB);
      await repository.refreshMine();
      environment.isOnline = false;
      await repository.completeLocally(groupA, 1);
      environment.isOnline = true;
      remote.onRpc = (call) async {
        if (call.args['p_group_id'] == groupA) {
          throw const PostgrestException(message: 'boom', code: 'XX000');
        }
        return {
          'applied': true,
          'code': 'completed',
          'operation_id': call.args['p_operation_id'],
          'group_id': groupB,
          'group_version': 3,
          'part_version': 3,
          'juz': 1,
        };
      };
      for (var attempt = 0; attempt < 8; attempt++) {
        await repository.flushPending();
        currentTime = currentTime.add(const Duration(hours: 2));
      }
      expect(
        remote.calls.where((c) => c.args['p_group_id'] == groupA).length,
        8,
      );

      // Normal sign-out wipes the cache, so dead letters still warn it, but
      // they never gate delivery (password update).
      expect(await repository.hasPending(), isTrue);
      expect(await repository.hasDeliverablePending(), isFalse);
      environment.setFeatureEnabled(false);
      expect(await repository.hasPending(), isTrue);
      environment.setFeatureEnabled(true);
      expect(repository.failedOperations(), hasLength(1));

      environment.isOnline = false;
      await repository.completeLocally(groupB, 1);
      environment.isOnline = true;
      await repository.flushPending();
      expect(
        remote.calls.where((c) => c.args['p_group_id'] == groupB).length,
        1,
      );
      expect(
        remote.calls.where((c) => c.args['p_group_id'] == groupA).length,
        8,
      );
    },
  );

  test(
    'A to B to A response cannot publish or persist under new A lease',
    () async {
      final pending = Completer<GroupKhatmahPage>();
      remote.onPage = (_, _) => pending.future;
      final before = prefs.getString('group_khatmah_cache_v1|$ownerA');
      final future = repository.refreshMine();
      final barrier = AccountDataBarrier.forPreferences(prefs);
      owner.currentOwnerId = ownerB;
      barrier.prepareOwner(ownerB);
      await barrier.markOwnerReady(ownerB);
      owner.currentOwnerId = ownerA;
      barrier.prepareOwner(ownerA);
      await barrier.markOwnerReady(ownerA);
      pending.complete(
        GroupKhatmahPage(
          groups: [fixture(groupA, ownerA, epochA)],
          nextCursor: null,
        ),
      );
      await future;
      expect(prefs.getString('group_khatmah_cache_v1|$ownerA'), before);
      expect(await repository.watchMine().first, isEmpty);
    },
  );

  test('audience and feature gates fail closed on cached stream', () async {
    remote.groups[groupA] = fixture(groupA, ownerA, epochA);
    await repository.refreshMine();
    final seen = <List<GroupKhatmah>>[];
    final subscription = repository.watchMine().listen(seen.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);
    expect(seen.last, isNotEmpty);
    environment.setAdult(false);
    await Future<void>.delayed(Duration.zero);
    expect(seen.last, isEmpty);
    environment.setAdult(true);
    environment.setFeatureEnabled(false);
    expect(await repository.watchMine().first, isEmpty);
    expect(prefs.getString('group_khatmah_cache_v1|$ownerA'), isNotNull);
  });

  test('repeated completion tap keeps one durable operation', () async {
    remote.groups[groupA] = fixture(groupA, ownerA, epochA);
    await repository.refreshMine();
    environment.isOnline = false;
    expect((await repository.completeLocally(groupA, 1)).isRight(), isTrue);
    expect((await repository.completeLocally(groupA, 1)).isRight(), isTrue);
    environment.isOnline = true;
    await repository.flushPending();
    expect(
      remote.calls.where((c) => c.function == 'complete_group_part').length,
      1,
    );
  });

  test('dispose closes active cache watchers with an empty snapshot', () async {
    remote.groups[groupA] = fixture(groupA, ownerA, epochA);
    await repository.refreshMine();
    final seen = <List<GroupKhatmah>>[];
    final first = Completer<void>();
    final done = Completer<void>();
    final subscription = repository.watchMine().listen((groups) {
      seen.add(groups);
      if (!first.isCompleted) first.complete();
    }, onDone: () => done.complete());
    addTearDown(subscription.cancel);
    await first.future;
    expect(seen.last, isNotEmpty);
    await repository.dispose();
    await done.future;
    expect(seen.last, isEmpty);
  });
}
