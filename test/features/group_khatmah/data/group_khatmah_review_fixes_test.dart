import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/group_khatmah/data/group_khatmah_repository_impl.dart';
import 'package:talia_quran/features/group_khatmah/domain/entities/group_khatmah.dart';
import 'package:talia_quran/features/group_khatmah/domain/repositories/group_khatmah_repository.dart';

import 'group_khatmah_test_support.dart';

class _FlipOfflineWake extends FakeWake {
  _FlipOfflineWake(this.environment);
  final MutableEnvironment environment;
  @override
  Future<void> reconcilePush({
    required String ownerId,
    required AccountDataLease lease,
    required DateTime? nextRetryAt,
  }) async {
    await super.reconcilePush(
      ownerId: ownerId,
      lease: lease,
      nextRetryAt: nextRetryAt,
    );
    environment.isOnline = false;
  }
}

void main() {
  late SharedPreferences prefs;
  late MutableOwner owner;
  late MutableEnvironment environment;
  late FakeRemote remote;
  late FakeWake wake;
  late DateTime now;
  late int nextId;
  late GroupKhatmahRepositoryImpl repository;

  GroupKhatmahRepositoryImpl build() => GroupKhatmahRepositoryImpl(
    preferences: prefs,
    owner: owner,
    remote: remote,
    wake: wake,
    environment: environment,
    operationId: () => [operation1, operation2][nextId++ % 2],
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
    nextId = 0;
    repository = build();
    addTearDown(() async {
      await repository.dispose();
      await environment.dispose();
    });
  });

  String? failureCode(Object? value) =>
      value is GroupKhatmahFailure ? value.code : null;

  Future<void> deadLetterCompletion() async {
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

  group('hasPending gates', () {
    test('sign-out gate counts dead letters; delivery gate does not', () async {
      await deadLetterCompletion();
      expect(repository.failedOperations(), hasLength(1));
      expect(await repository.hasPending(), isTrue);
      expect(await repository.hasDeliverablePending(), isFalse);
      expect(
        prefs.getString('group_khatmah_cache_v1|$ownerA'),
        contains(operation1),
      );
    });

    test(
      'unavailable feature or non-adult profile still warns sign-out',
      () async {
        remote.groups[groupA] = fixture(groupA, ownerA, epochA);
        await repository.refreshMine();
        await repository.completeLocally(groupA, 1);
        expect(await repository.hasPending(), isTrue);
        expect(await repository.hasDeliverablePending(), isTrue);

        environment.setFeatureEnabled(false);
        expect(await repository.hasPending(), isTrue);
        expect(await repository.hasDeliverablePending(), isFalse);
        environment.setFeatureEnabled(true);

        environment.setAdult(false);
        expect(await repository.hasPending(), isTrue);
        expect(await repository.hasDeliverablePending(), isFalse);
        environment.setAdult(true);
        expect(await repository.hasDeliverablePending(), isTrue);
      },
    );

    test('no intents means nothing pending', () async {
      expect(await repository.hasPending(), isFalse);
      expect(await repository.hasDeliverablePending(), isFalse);
    });
  });

  group('transport deferral backoff and age cap', () {
    Map<String, dynamic> storedIntent() {
      final raw = prefs.getString('group_khatmah_cache_v1|$ownerA')!;
      return ((jsonDecode(raw) as Map<String, dynamic>)['intents'] as List)
              .single
          as Map<String, dynamic>;
    }

    Future<void> queueCompletion() async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      await repository.refreshMine();
      await repository.completeLocally(groupA, 1);
      remote.onRpc = (_) async => throw const SocketException('offline');
    }

    test(
      'backs off exponentially, capped at one hour, without spending attempts',
      () async {
        await queueCompletion();
        final expected = [30, 60, 120, 240, 480, 960, 1920, 3600, 3600];
        for (final seconds in expected) {
          await repository.flushPending();
          final intent = storedIntent();
          expect(intent['attemptCount'], 0);
          expect(
            DateTime.parse(intent['nextRetryAt'] as String).difference(now),
            Duration(seconds: seconds),
          );
          // Not due yet: another flush must not call the server again.
          final calls = remote.calls.length;
          now = now.add(Duration(seconds: seconds - 1));
          await repository.flushPending();
          expect(remote.calls.length, calls);
          now = now.add(const Duration(seconds: 1));
        }
      },
    );

    test(
      'older than 48h becomes recovery-required instead of deferring forever',
      () async {
        await queueCompletion();
        now = now.add(const Duration(hours: 47));
        await repository.flushPending();
        expect(repository.failedOperations(), isEmpty);
        expect(await repository.hasDeliverablePending(), isTrue);

        now = now.add(const Duration(hours: 2));
        await repository.flushPending();
        expect(repository.failedOperations(), hasLength(1));
        expect(await repository.hasDeliverablePending(), isFalse);
        expect(await repository.hasPending(), isTrue);
        // Dead-lettered intents are not re-sent automatically.
        final calls = remote.calls.length;
        now = now.add(const Duration(hours: 2));
        await repository.flushPending();
        expect(remote.calls.length, calls);

        // The user can retry; the fresh window allows another day of deferral.
        expect(
          (await repository.retryFailedOperation(operation1)).isRight(),
          isTrue,
        );
        await repository.flushPending();
        expect(repository.failedOperations(), isEmpty);
      },
    );

    test(
      'create that finds the client offline after journaling defers without spending an attempt',
      () async {
        final flipping = _FlipOfflineWake(environment);
        wake = flipping;
        await repository.dispose();
        repository = build();
        final result = await repository.create('Shared reading', 'Reader');
        expect(result.swap().toOption().toNullable(), isA<NetworkFailure>());
        expect(remote.calls, isEmpty, reason: 'request was never sent');
        final intent = storedIntent();
        expect(intent['attemptCount'], 0);
        expect(intent['deferralCount'], 1);
        expect(await repository.hasDeliverablePending(), isTrue);
        expect(repository.failedOperations(), isEmpty);
      },
    );
  });

  group('P2-1 transport errors do not spend attempts', () {
    final errors = <String, Object Function()>{
      'socket': () => const SocketException('offline'),
      'timeout': () => TimeoutException('offline'),
      'http client': () => http.ClientException('offline'),
      'auth retryable': () => AuthRetryableFetchException(message: 'offline'),
    };
    errors.forEach((name, make) {
      test(
        '$name keeps completion pending after more than 8 flushes',
        () async {
          remote.groups[groupA] = fixture(groupA, ownerA, epochA);
          await repository.refreshMine();
          await repository.completeLocally(groupA, 1);
          remote.onRpc = (_) async => throw make();
          for (var i = 0; i < 12; i++) {
            await repository.flushPending();
            now = now.add(const Duration(hours: 2));
          }
          expect(repository.failedOperations(), isEmpty);
          expect(await repository.hasPending(), isTrue);
          expect(remote.calls.length, 12);
          final part = (await repository.watchMine().first).single.part(1)!;
          expect(part.isCompletionPending, isTrue);
          expect(part.isCompletionFailed, isFalse);
        },
      );
    });
  });

  group('P2-2 unknown outcome of online-only actions', () {
    test(
      'create transport failure reports pending and blocks a second create',
      () async {
        remote.onRpc = (_) async => throw TimeoutException('lost');
        final first = await repository.create('Shared reading', 'Reader');
        expect(
          failureCode(first.swap().toOption().toNullable()),
          'outcome_pending',
        );
        expect(remote.calls.length, 1);

        final second = await repository.create('Shared reading', 'Reader');
        expect(
          failureCode(second.swap().toOption().toNullable()),
          'outcome_pending',
        );
        expect(remote.calls.length, 1, reason: 'no duplicate create RPC');
        expect(nextId, 1, reason: 'no second operation id issued');

        // The same operation completes later through the normal flush.
        remote.onRpc = (call) async {
          expect(call.args['p_operation_id'], operation1);
          remote.groups[groupA] = fixture(groupA, ownerA, epochA);
          return {
            'applied': true,
            'code': 'created',
            'operation_id': operation1,
            'group_id': groupA,
            'group_version': 1,
            'membership_epoch': epochA,
          };
        };
        now = now.add(const Duration(hours: 1));
        await repository.flushPending();
        expect(await repository.hasPending(), isFalse);
        expect((await repository.watchMine().first).single.id, groupA);
      },
    );

    test(
      'claim transport failure reports pending rather than failed',
      () async {
        remote.groups[groupA] = fixture(
          groupA,
          ownerA,
          epochA,
          firstStatus: GroupPartStatus.open,
          firstVersion: 1,
        );
        await repository.refreshMine();
        remote.onRpc = (_) async => throw const SocketException('lost');
        final result = await repository.claim(groupA, 1);
        expect(
          failureCode(result.swap().toOption().toNullable()),
          'outcome_pending',
        );
        expect(repository.failedOperations(), isEmpty);
      },
    );
  });

  group('P3-1 conflict survives refresh failure', () {
    test('claim conflict still returns GroupPartConflictFailure', () async {
      remote.groups[groupA] = fixture(
        groupA,
        ownerA,
        epochA,
        firstStatus: GroupPartStatus.open,
        firstVersion: 1,
      );
      await repository.refreshMine();
      remote.onRpc = (_) async {
        remote.onGroup = (_, _) async => throw TimeoutException('refresh');
        return {'applied': false, 'code': 'conflict'};
      };
      final result = await repository.claim(groupA, 1);
      expect(
        result.swap().toOption().toNullable(),
        isA<GroupPartConflictFailure>(),
      );
    });
  });

  group('P4 flush single flight', () {
    test('concurrent flushPending callers share one run', () async {
      remote.groups[groupA] = fixture(groupA, ownerA, epochA);
      await repository.refreshMine();
      await repository.completeLocally(groupA, 1);
      final gate = Completer<void>();
      remote.onRpc = (call) async {
        await gate.future;
        return {
          'applied': true,
          'code': 'completed',
          'operation_id': call.args['p_operation_id'],
          'group_id': groupA,
          'group_version': 3,
          'part_version': 3,
        };
      };
      final a = repository.flushPending();
      final b = repository.flushPending();
      gate.complete();
      await Future.wait([a, b]);
      expect(remote.calls.length, 1);
      expect(await repository.hasPending(), isFalse);
    });
  });
}
