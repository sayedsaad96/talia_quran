import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_repository_impl.dart';
import 'package:talia_quran/features/group_khatmah/data/supabase_group_khatmah_remote.dart';
import 'package:talia_quran/features/group_khatmah/domain/repositories/group_khatmah_repository.dart';
import 'package:talia_quran/features/group_khatmah/domain/entities/group_khatmah.dart';

import 'group_khatmah_test_support.dart';

void main() {
  late SharedPreferences prefs;
  late MutableOwner owner;
  late MutableEnvironment environment;
  late FakeRemote remote;
  late FakeWake wake;
  late DateTime now;
  late GroupKhatmahRepositoryImpl repository;

  GroupKhatmahRepositoryImpl build() => GroupKhatmahRepositoryImpl(
    preferences: prefs,
    owner: owner,
    remote: remote,
    wake: wake,
    environment: environment,
    operationId: () => operation1,
    clock: () => now,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = MutableOwner(ownerA);
    AccountDataBarrier.forPreferences(prefs).owner = owner;
    environment = MutableEnvironment();
    remote = FakeRemote();
    wake = FakeWake();
    now = DateTime.utc(2026, 10, 23);
    repository = build();
    addTearDown(() async {
      await repository.dispose();
      await environment.dispose();
    });
  });

  Future<void> makeDeadLetter() async {
    remote.groups[groupA] = fixture(groupA, ownerA, epochA);
    await repository.refreshMine();
    await repository.completeLocally(groupA, 1);
    remote.onRpc = (_) async =>
        throw const PostgrestException(message: 'boom', code: 'XX000');
    for (var attempt = 0; attempt < 8; attempt++) {
      await repository.flushPending();
      now = now.add(const Duration(hours: 2));
    }
  }

  test(
    'dead letter signals recovery and explicit retry reuses operation',
    () async {
      await makeDeadLetter();
      final part = (await repository.watchMine().first).single.part(1)!;
      expect(part.isCompletionPending, isFalse);
      expect(part.isCompletionFailed, isTrue);
      final retap = await repository.completeLocally(groupA, 1);
      expect(
        retap.fold(
          (failure) =>
              failure is GroupKhatmahFailure &&
              failure.code == 'recovery_required',
          (_) => false,
        ),
        isTrue,
      );
      expect(remote.calls.length, 8);
      expect(
        (await repository.retryFailedCompletion(groupA, 1)).isRight(),
        isTrue,
      );
      final active = (await repository.watchMine().first).single.part(1)!;
      expect(active.isCompletionPending, isTrue);
      expect(active.isCompletionFailed, isFalse);
      remote.onRpc = (call) async => {
        'applied': true,
        'code': 'completed',
        'operation_id': call.args['p_operation_id'],
        'group_id': groupA,
        'group_version': 3,
        'part_version': 3,
      };
      await repository.flushPending();
      expect(remote.calls.last.args['p_operation_id'], operation1);
      expect(await repository.hasPending(), isFalse);
    },
  );

  test('explicit discard removes only local failed completion', () async {
    await makeDeadLetter();
    expect(
      (await repository.discardFailedCompletion(groupA, 1)).isRight(),
      isTrue,
    );
    expect(await repository.hasPending(), isFalse);
    final part = (await repository.watchMine().first).single.part(1)!;
    expect(part.isCompletionFailed, isFalse);
    expect(part.isCompletionPending, isFalse);
  });

  test(
    'lost create acknowledgement exposes recovery before any group is known',
    () async {
      remote.onRpc = (_) async =>
          throw const PostgrestException(message: 'boom', code: 'XX000');
      await repository.create('Shared reading', 'Reader');
      for (var attempt = 0; attempt < 8; attempt++) {
        await repository.flushPending();
        now = now.add(const Duration(hours: 2));
      }
      final failed = repository.failedOperations().single;
      expect(failed.operationId, operation1);
      expect(failed.action, 'create');
      expect(
        (await repository.retryFailedOperation(operation1)).isRight(),
        isTrue,
      );
      expect(repository.failedOperations(), isEmpty);
      await repository.flushPending();
      expect(remote.calls.last.args['p_operation_id'], operation1);
    },
  );

  test(
    'explicit generic discard releases failed work with no current claim',
    () async {
      await makeDeadLetter();
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        firstStatus: GroupPartStatus.open,
        firstVersion: 3,
      ).copyWith(version: 3);
      await repository.refreshMine();
      expect(
        (await repository.watchMine().first).single.part(1)!.isCompletionFailed,
        isFalse,
      );
      expect(repository.failedOperations().single.operationId, operation1);
      expect(
        (await repository.discardFailedOperation(operation1)).isRight(),
        isTrue,
      );
      expect(await repository.hasPending(), isFalse);
      expect(
        (await repository.discardFailedOperation(operation1)).isLeft(),
        isTrue,
      );
    },
  );

  test(
    'authoritative membership removal purges failed requests as well as names',
    () async {
      await makeDeadLetter();
      remote.groups.clear();
      await repository.refreshMine();
      expect(await repository.watchMine().first, isEmpty);
      expect(repository.failedOperations(), isEmpty);
      expect(await repository.hasPending(), isFalse);
    },
  );

  test('auth interruption defers without consuming retry budget', () async {
    remote.groups[groupA] = fixture(groupA, ownerA, epochA);
    await repository.refreshMine();
    await repository.completeLocally(groupA, 1);
    remote.onRpc = (_) async => throw const GroupRemoteOwnerChanged();
    await repository.flushPending();
    final raw = prefs.getString('group_khatmah_cache_v1|$ownerA')!;
    final intent =
        (jsonDecode(raw) as Map<String, dynamic>)['intents'][0]
            as Map<String, dynamic>;
    expect(intent['attemptCount'], 0);
    expect(intent['nextRetryAt'], isNotNull);
    expect(await repository.hasRunnablePending(), isFalse);
    now = now.add(const Duration(seconds: 31));
    remote.onRpc = (call) async => {
      'applied': true,
      'code': 'completed',
      'operation_id': call.args['p_operation_id'],
      'group_id': groupA,
      'group_version': 3,
      'part_version': 3,
    };
    await repository.flushPending();
    expect(remote.calls.length, 2);
    expect(await repository.hasPending(), isFalse);
  });

  test(
    'revoked SQL session waits for recovery without exhausting the journal',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      await repository.refreshMine();
      await repository.completeLocally(groupA, 1);
      remote.onRpc = (_) async => throw const PostgrestException(
        message: 'group_session_required',
        code: 'P0001',
      );
      for (var attempt = 0; attempt < 9; attempt++) {
        await repository.flushPending();
        now = now.add(const Duration(seconds: 31));
      }
      final raw =
          jsonDecode(prefs.getString('group_khatmah_cache_v1|$ownerA')!) as Map;
      expect(raw['intents'].single['attemptCount'], 0);
      expect(raw['intents'].single['deadLetter'], isFalse);
      expect(await repository.hasPending(), isTrue);
    },
  );

  test(
    'offline restart reconciles durable wake without remote calls',
    () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      await repository.refreshMine();
      await repository.completeLocally(groupA, 1);
      wake.pushes.clear();
      await repository.dispose();
      repository = build();
      environment.isOnline = false;
      expect((await repository.reconcilePendingWake()).isRight(), isTrue);
      expect(wake.pushes, [ownerA]);
      expect(remote.calls, isEmpty);
    },
  );
}
