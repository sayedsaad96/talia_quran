import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/kids_home_mission_cloud_merge.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/kids_home_mission_child_sync.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_mappers.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_local_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_home_mission.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _FakeProgressEventsBus implements ProgressEventsBus {
  @override
  void notify(ProgressChangedReason reason) {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingQueue implements CloudSyncQueue {
  @override
  Future<void> enqueue(String kind) async => throw StateError('isar closed');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingQueue implements CloudSyncQueue {
  final kinds = <String>[];

  @override
  Future<void> enqueue(String kind) async => kinds.add(kind);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

KidsHomeMission _mission(
  String id,
  KidsHomeMissionStatus status, {
  bool pending = false,
  DateTime? createdAt,
}) => KidsHomeMission(
  id: id,
  title: 'مهمة $id',
  status: status,
  createdAt: createdAt ?? DateTime.utc(2026, 10, 1, 8),
  reportedAt: status == KidsHomeMissionStatus.assigned
      ? null
      : DateTime.utc(2026, 10, 1, 9),
  pendingReportSync: pending,
);

Map<String, dynamic> _row(String id, String status, {String? createdAt}) => {
  'id': int.parse(id),
  'title': 'مهمة $id',
  'status': status,
  'created_at': createdAt ?? '2026-10-01T08:00:00Z',
  'reported_at': status == 'assigned' ? null : '2026-10-01T09:00:00Z',
  'acknowledged_at': status == 'acknowledged' ? '2026-10-01T10:00:00Z' : null,
};

void main() {
  late SharedPreferences prefs;
  late MemorizationPlusLocalDatasourceImpl datasource;
  late KidsHomeMissionChildSync sync;
  late _RecordingQueue queue;
  late MemorizationKidsLocalService service;
  const ownerId = 'child-1';
  const provider = FixedRecordOwnerProvider(ownerId);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    datasource = MemorizationPlusLocalDatasourceImpl(prefs, owner: provider);
    sync = KidsHomeMissionChildSync(
      datasource,
      MemorizationCloudMappers(const ProgressMetricsService()),
      provider,
    );
    queue = _RecordingQueue();
    service = MemorizationKidsLocalService(
      datasource,
      _UnusedQuranRepository(),
      _FakeStreakReader(),
      _FakeProgressEventsBus(),
      queue,
      owner: provider,
    );
  });

  Future<List<KidsHomeMission>> stored() => datasource.getHomeMissions();

  group('KidsHomeMissionCloudMerge', () {
    test('server acknowledged wins over a local reported mission', () {
      final merged = KidsHomeMissionCloudMerge.merge(
        local: [_mission('1', KidsHomeMissionStatus.reported, pending: true)],
        remote: [_mission('1', KidsHomeMissionStatus.acknowledged)],
      );
      expect(merged.single.status, KidsHomeMissionStatus.acknowledged);
      expect(merged.single.pendingReportSync, isFalse);
    });

    test('server reported wins over a local assigned mission', () {
      final merged = KidsHomeMissionCloudMerge.merge(
        local: [_mission('1', KidsHomeMissionStatus.assigned)],
        remote: [_mission('1', KidsHomeMissionStatus.reported)],
      );
      expect(merged.single.status, KidsHomeMissionStatus.reported);
    });

    test('server assigned keeps a pending local report', () {
      final local = _mission(
        '1',
        KidsHomeMissionStatus.reported,
        pending: true,
      );
      final merged = KidsHomeMissionCloudMerge.merge(
        local: [local],
        remote: [_mission('1', KidsHomeMissionStatus.assigned)],
      );
      expect(merged.single, local);
      expect(merged.single.pendingReportSync, isTrue);
    });

    test('adds unknown server rows oldest first; local-only rows stay', () {
      final localOnly = _mission('local-9', KidsHomeMissionStatus.assigned);
      final merged = KidsHomeMissionCloudMerge.merge(
        local: [localOnly],
        remote: [
          _mission(
            '3',
            KidsHomeMissionStatus.assigned,
            createdAt: DateTime.utc(2026, 10, 2),
          ),
          _mission(
            '2',
            KidsHomeMissionStatus.assigned,
            createdAt: DateTime.utc(2026, 10, 1),
          ),
        ],
      );
      expect(merged.map((m) => m.id), ['local-9', '2', '3']);
      expect(merged.first, localOnly);
    });
  });

  group('reportHomeMission', () {
    Future<String> addAssigned() async {
      await datasource.saveHomeMissions([
        _mission('7', KidsHomeMissionStatus.assigned),
      ]);
      return '7';
    }

    test('a linked child saves pendingReportSync and queues a push', () async {
      final id = await addAssigned();
      final result = await service.reportHomeMission(id, markPendingSync: true);
      expect(result.isRight(), isTrue);
      final saved = (await stored()).single;
      expect(saved.status, KidsHomeMissionStatus.reported);
      expect(saved.pendingReportSync, isTrue);
      expect(queue.kinds, [CloudSyncQueueKind.kidsProgressPush]);
    });

    test('an unlinked child stores locally only, no flag, no queue', () async {
      final id = await addAssigned();
      await service.reportHomeMission(id);
      final saved = (await stored()).single;
      expect(saved.status, KidsHomeMissionStatus.reported);
      expect(saved.pendingReportSync, isFalse);
      expect(queue.kinds, isEmpty);
    });

    test('a throwing enqueue never fails a saved report', () async {
      final id = await addAssigned();
      final throwing = MemorizationKidsLocalService(
        datasource,
        _UnusedQuranRepository(),
        _FakeStreakReader(),
        _FakeProgressEventsBus(),
        _ThrowingQueue(),
        owner: provider,
      );
      final result = await throwing.reportHomeMission(
        id,
        markPendingSync: true,
      );
      expect(result.isRight(), isTrue);
      expect((await stored()).single.pendingReportSync, isTrue);
    });

    test('a repeated report does not queue again', () async {
      final id = await addAssigned();
      await service.reportHomeMission(id, markPendingSync: true);
      await service.reportHomeMission(id, markPendingSync: true);
      expect(queue.kinds, hasLength(1));
    });
  });

  group('push', () {
    test('offline report stays pending; the next push calls the RPC once and '
        'clears the flag', () async {
      await datasource.saveHomeMissions([
        _mission('7', KidsHomeMissionStatus.assigned),
      ]);
      await service.reportHomeMission('7', markPendingSync: true);

      final calls = <int>[];
      // Offline: the RPC throws, the flag survives.
      final hadTransient = await sync.push(
        ownerId: ownerId,
        reportRpc: (id) async => throw Exception('offline'),
      );
      expect(hadTransient, isTrue);
      expect((await stored()).single.pendingReportSync, isTrue);

      final ok = await sync.push(
        ownerId: ownerId,
        reportRpc: (id) async => calls.add(id),
      );
      expect(ok, isFalse);
      expect(calls, [7]);
      expect((await stored()).single.pendingReportSync, isFalse);
      expect((await stored()).single.status, KidsHomeMissionStatus.reported);

      // Nothing pending any more: no further call.
      await sync.push(ownerId: ownerId, reportRpc: (id) async => calls.add(id));
      expect(calls, [7]);
    });

    test(
      'local-only ids are skipped; a transient failure does not block others '
      'and is reported',
      () async {
        await datasource.saveHomeMissions([
          _mission('local-1', KidsHomeMissionStatus.reported, pending: true),
          _mission('8', KidsHomeMissionStatus.reported, pending: true),
          _mission('9', KidsHomeMissionStatus.reported, pending: true),
        ]);
        final calls = <int>[];
        final hadTransient = await sync.push(
          ownerId: ownerId,
          reportRpc: (id) async {
            calls.add(id);
            if (id == 8) throw Exception('socket timeout');
          },
        );
        expect(hadTransient, isTrue);
        expect(calls, [8, 9]);
        final byId = {for (final m in await stored()) m.id: m};
        expect(byId['local-1']!.pendingReportSync, isTrue);
        expect(byId['8']!.pendingReportSync, isTrue);
        expect(byId['9']!.pendingReportSync, isFalse);
      },
    );

    for (final message in ['Child link is not active', 'Mission not found']) {
      test(
        'terminal "$message" clears the flag, keeps reported, no transient',
        () async {
          await datasource.saveHomeMissions([
            _mission('8', KidsHomeMissionStatus.reported, pending: true),
          ]);
          var calls = 0;
          final hadTransient = await sync.push(
            ownerId: ownerId,
            reportRpc: (id) async {
              calls++;
              throw Exception('PostgrestException: $message');
            },
          );
          expect(hadTransient, isFalse);
          expect(calls, 1);
          final saved = (await stored()).single;
          expect(saved.pendingReportSync, isFalse);
          expect(saved.status, KidsHomeMissionStatus.reported);

          // Not retried on the next sync.
          await sync.push(ownerId: ownerId, reportRpc: (id) async => calls++);
          expect(calls, 1);
        },
      );
    }

    test('a stale owner neither calls the RPC nor clears anything', () async {
      await datasource.saveHomeMissions([
        _mission('8', KidsHomeMissionStatus.reported, pending: true),
      ]);
      var calls = 0;
      await sync.push(
        ownerId: 'someone-else',
        reportRpc: (id) async => calls++,
      );
      expect(calls, 0);
      expect((await stored()).single.pendingReportSync, isTrue);
    });
  });

  group('pull', () {
    test('server assigned while local reported+pending keeps local', () async {
      await datasource.saveHomeMissions([
        _mission('7', KidsHomeMissionStatus.reported, pending: true),
      ]);
      await sync.pull(
        ownerId: ownerId,
        fetchRows: () async => [_row('7', 'assigned')],
      );
      final saved = (await stored()).single;
      expect(saved.status, KidsHomeMissionStatus.reported);
      expect(saved.pendingReportSync, isTrue);
    });

    test('server acknowledged and new rows are merged', () async {
      await datasource.saveHomeMissions([
        _mission('7', KidsHomeMissionStatus.reported),
        _mission('local-1', KidsHomeMissionStatus.assigned),
      ]);
      await sync.pull(
        ownerId: ownerId,
        fetchRows: () async => [
          _row('7', 'acknowledged'),
          _row('8', 'assigned', createdAt: '2026-10-02T08:00:00Z'),
        ],
      );
      final saved = await stored();
      expect(saved.map((m) => m.id), ['7', 'local-1', '8']);
      expect(saved.first.status, KidsHomeMissionStatus.acknowledged);
    });

    test(
      'a failing pull after link revocation leaves local untouched',
      () async {
        final before = [
          _mission('7', KidsHomeMissionStatus.reported, pending: true),
          _mission('local-1', KidsHomeMissionStatus.assigned),
        ];
        await datasource.saveHomeMissions(before);
        await sync.pull(
          ownerId: ownerId,
          fetchRows: () async => throw Exception('Child link is not active'),
        );
        expect(await stored(), before);
      },
    );

    test('server acknowledged clears a pending local report', () async {
      await datasource.saveHomeMissions([
        _mission('7', KidsHomeMissionStatus.reported, pending: true),
      ]);
      await sync.pull(
        ownerId: ownerId,
        fetchRows: () async => [_row('7', 'acknowledged')],
      );
      final saved = (await stored()).single;
      expect(saved.status, KidsHomeMissionStatus.acknowledged);
      expect(saved.pendingReportSync, isFalse);
    });

    test('an empty server answer keeps local-only and pending rows', () async {
      final localOnly = _mission('local-1', KidsHomeMissionStatus.assigned);
      final pending = _mission(
        '9',
        KidsHomeMissionStatus.reported,
        pending: true,
      );
      await datasource.saveHomeMissions([
        _mission('7', KidsHomeMissionStatus.assigned),
        localOnly,
        pending,
      ]);
      await sync.pull(ownerId: ownerId, fetchRows: () async => []);
      expect(await stored(), [localOnly, pending]);
    });

    test('an orphan server-id mission is dropped on a successful pull '
        '(P3-R14)', () async {
      await datasource.saveHomeMissions([
        _mission('7', KidsHomeMissionStatus.assigned),
        _mission('8', KidsHomeMissionStatus.reported),
      ]);
      await sync.pull(
        ownerId: ownerId,
        fetchRows: () async => [_row('8', 'reported')],
      );
      expect((await stored()).map((m) => m.id), ['8']);
    });

    test('a pending orphan report is kept on pull (P3-R14)', () async {
      final pending = _mission(
        '7',
        KidsHomeMissionStatus.reported,
        pending: true,
      );
      await datasource.saveHomeMissions([pending]);
      await sync.pull(
        ownerId: ownerId,
        fetchRows: () async => [_row('8', 'assigned')],
      );
      final byId = {for (final m in await stored()) m.id: m};
      expect(byId['7'], pending);
      expect(byId.keys, containsAll(['7', '8']));
    });

    test('a failed fetch never drops orphans', () async {
      final before = [_mission('7', KidsHomeMissionStatus.assigned)];
      await datasource.saveHomeMissions(before);
      await sync.pull(
        ownerId: ownerId,
        fetchRows: () async => throw Exception('network down'),
      );
      expect(await stored(), before);
    });

    test('a pull for a stale owner does not write', () async {
      final before = [_mission('7', KidsHomeMissionStatus.assigned)];
      await datasource.saveHomeMissions(before);
      await sync.pull(
        ownerId: 'someone-else',
        fetchRows: () async => [_row('7', 'acknowledged')],
      );
      expect(await stored(), before);
    });
  });

  test('concurrent report and pull-merge never lose either update', () async {
    await datasource.saveHomeMissions([
      _mission('1', KidsHomeMissionStatus.assigned),
      _mission('2', KidsHomeMissionStatus.assigned),
    ]);

    final futures = [
      service.reportHomeMission('1', markPendingSync: true),
      sync.pull(
        ownerId: ownerId,
        fetchRows: () async => [
          _row('1', 'assigned'),
          _row('2', 'reported'),
          _row('3', 'assigned', createdAt: '2026-10-02T08:00:00Z'),
        ],
      ),
    ];
    await Future.wait<Object?>(futures);

    final byId = {for (final m in await stored()) m.id: m};
    expect(byId.keys, containsAll(['1', '2', '3']));
    expect(byId['1']!.status, KidsHomeMissionStatus.reported);
    expect(byId['1']!.pendingReportSync, isTrue);
    expect(byId['2']!.status, KidsHomeMissionStatus.reported);
    expect(byId['3']!.status, KidsHomeMissionStatus.assigned);
  });

  test('a slow pull-merge cannot overwrite a concurrent report', () async {
    await datasource.saveHomeMissions([
      _mission('1', KidsHomeMissionStatus.assigned),
    ]);

    // The merge reads, then yields before writing: without the per-owner
    // lock the concurrent report would be written first and then clobbered.
    final slowMerge = datasource.updateHomeMissions((local) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return KidsHomeMissionCloudMerge.merge(
        local: local,
        remote: [_mission('2', KidsHomeMissionStatus.assigned)],
      );
    });
    final report = service.reportHomeMission('1', markPendingSync: true);
    await Future.wait<Object?>([slowMerge, report]);

    final byId = {for (final m in await stored()) m.id: m};
    expect(byId.keys, containsAll(['1', '2']));
    expect(byId['1']!.status, KidsHomeMissionStatus.reported);
    expect(byId['1']!.pendingReportSync, isTrue);
  });

  test('the lock is released after a throwing mutate', () async {
    await datasource.saveHomeMissions([
      _mission('1', KidsHomeMissionStatus.assigned),
    ]);
    await expectLater(
      datasource.updateHomeMissions((_) async => throw StateError('boom')),
      throwsStateError,
    );
    final next = await datasource.updateHomeMissions(
      (local) async => [for (final m in local) m.copyWith(title: 'after')],
    );
    expect(next.single.title, 'after');
    expect((await stored()).single.title, 'after');
  });
}
