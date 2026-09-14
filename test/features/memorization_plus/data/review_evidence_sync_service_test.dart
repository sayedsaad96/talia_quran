import 'dart:async';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/review_evidence_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/review_evidence_sync_service.dart';

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
      if (File(dllPath).existsSync()) {
        await Isar.initializeIsarCore(libraries: {Abi.current(): dllPath});
        _isarCoreInitialized = true;
        return;
      }
    }
  }
  await Isar.initializeIsarCore();
  _isarCoreInitialized = true;
}

void main() {
  group('ReviewEvidenceSyncService', () {
    late Directory tempDir;
    late Isar isar;
    late SharedPreferences prefs;
    late _FakeEvidenceTransport transport;
    late ReviewEvidenceSyncService service;

    setUp(() async {
      await _initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({
        'use_review_evidence_transport': true,
      });
      prefs = await SharedPreferences.getInstance();
      tempDir = await Directory.systemTemp.createTemp(
        'talia_evidence_service_',
      );
      isar = await Isar.open(
        [
          IsarReviewEvidenceEventSchema,
          IsarReviewEffectOutboxSchema,
          CloudSyncQueueItemSchema,
        ],
        directory: tempDir.path,
        name: 'evidence_service_${DateTime.now().microsecondsSinceEpoch}',
      );
      transport = _FakeEvidenceTransport();
      service = ReviewEvidenceSyncService(
        local: ReviewEvidenceLocalDatasource(isar),
        owner: const FixedRecordOwnerProvider('owner-a'),
        prefs: prefs,
        transport: transport,
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test(
      'append acknowledgement clears only the event snapshot sent to the server',
      () async {
        final first = _event();
        final later = _event(id: 'event-b', taskId: 'task-b');
        await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(first));
        transport.onAppend = (events) async {
          await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(later));
          return const [
            {
              'event_id': 'event-a',
              'result': 'alreadyApplied',
              'server_sequence': 9,
            },
          ];
        };

        await service.pushPending();

        final pending = await service.pendingEvents();
        expect(pending.map((event) => event.eventId), ['event-b']);
      },
    );

    test(
      'each reconciliation starts from zero and imports without an upload receipt',
      () async {
        transport.pullPages = [
          [_cloudRow('remote-a', 1), _cloudRow('remote-b', 2)],
          const [],
        ];

        await service.pull();
        await service.pull();

        expect(transport.pullCursors, everyElement((cursor) => cursor.$1 == 0));
        expect(await service.pendingEvents(), isEmpty);
        expect(await isar.isarReviewEvidenceEvents.count(), 2);
      },
    );

    test('sign-out flush drains more than one bounded append batch', () async {
      await isar.writeTxn(() async {
        await isar.isarReviewEvidenceEvents.putAll([
          for (var index = 0; index < 101; index += 1)
            _event(id: 'event-$index', taskId: 'task-$index'),
        ]);
      });
      var calls = 0;
      transport.onAppend = (events) async {
        calls += 1;
        return events
            .map(
              (event) => {
                'event_id': event['event_id'],
                'result': 'applied',
                'server_sequence': calls,
              },
            )
            .toList();
      };

      expect(await service.flushPending(), isTrue);
      expect(calls, 2);
      expect(await service.pendingEvents(), isEmpty);
    });

    test(
      'owner change during append response cannot acknowledge its receipt',
      () async {
        final owner = _MutableOwner('owner-a');
        final guarded = ReviewEvidenceSyncService(
          local: ReviewEvidenceLocalDatasource(isar),
          owner: owner,
          prefs: prefs,
          transport: transport,
        );
        await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(_event()));
        transport.onAppend = (_) async {
          owner.currentOwnerId = 'owner-b';
          return const [
            {'event_id': 'event-a', 'result': 'applied', 'server_sequence': 1},
          ];
        };

        await expectLater(
          guarded.pushPending(),
          throwsA(isA<AccountDataUnavailableException>()),
        );
        final effect = await isar.isarReviewEffectOutboxs
            .filter()
            .eventIdEqualTo('event-a')
            .findFirst();
        expect(effect?.processedAt, isNull);
      },
    );

    test(
      'same-owner generation invalidation prevents upload acknowledgement and pull merge',
      () async {
        final barrier = AccountDataBarrier.forPreferences(prefs);
        final guarded = ReviewEvidenceSyncService(
          local: ReviewEvidenceLocalDatasource(isar),
          owner: const FixedRecordOwnerProvider('owner-a'),
          prefs: prefs,
          transport: transport,
          barrier: barrier,
        );
        await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(_event()));

        final resetStarted = Completer<void>();
        final releaseReset = Completer<void>();
        final reset = barrier.clear(() async {
          resetStarted.complete();
          await releaseReset.future;
        });
        await resetStarted.future;
        await expectLater(
          guarded.pushPending(),
          throwsA(isA<AccountDataUnavailableException>()),
        );
        expect(transport.appendPayloads, isEmpty);
        releaseReset.complete();
        await reset;

        transport.onAppend = (_) async {
          barrier.invalidate();
          return const [
            {'event_id': 'event-a', 'result': 'applied', 'server_sequence': 1},
          ];
        };

        await expectLater(
          guarded.pushPending(),
          throwsA(isA<AccountDataUnavailableException>()),
        );
        var receipt = await isar.isarReviewEffectOutboxs
            .filter()
            .eventIdEqualTo('event-a')
            .findFirst();
        expect(receipt?.processedAt, isNull);

        await barrier.clear(() async {});
        transport
          ..onAppend = null
          ..pullPages = [
            [_cloudRow('remote-a', 1)],
          ]
          ..onPull =
              ({
                required ownerId,
                required cursorSequence,
                required cursorEventId,
              }) async {
                barrier.invalidate();
                return [_cloudRow('remote-a', 1)];
              };

        await expectLater(
          guarded.pull(),
          throwsA(isA<AccountDataUnavailableException>()),
        );
        expect(
          await isar.isarReviewEvidenceEvents
              .filter()
              .eventIdEqualTo('remote-a')
              .count(),
          0,
        );
        receipt = await isar.isarReviewEffectOutboxs
            .filter()
            .eventIdEqualTo('event-a')
            .findFirst();
        expect(receipt?.processedAt, isNull);
      },
    );

    test(
      'out-of-order intermediate pull row rejects the page before merge',
      () async {
        transport.pullPages = [
          [_cloudRow('remote-b', 2), _cloudRow('remote-a', 1)],
        ];

        await expectLater(service.pull(), throwsA(isA<FormatException>()));
        expect(await isar.isarReviewEvidenceEvents.count(), 0);
      },
    );

    test(
      'disabled transport preserves pending receipt without a network call',
      () async {
        await prefs.setBool('use_review_evidence_transport', false);
        await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(_event()));

        await service.pushPending();

        expect(await service.pendingEvents(), hasLength(1));
        expect(transport.appendPayloads, isEmpty);
      },
    );

    test(
      'explicit dead-letter recovery retries the identical persisted event ID once',
      () async {
        await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(_event()));
        final queue = CloudSyncQueue(
          isar,
          const FixedRecordOwnerProvider('owner-a'),
        );
        transport.onAppend = (_) async => throw StateError('offline');
        await queue.enqueue(CloudSyncQueueKind.reviewEvidencePush);
        for (
          var attempt = 0;
          attempt < CloudSyncQueue.maxAttempts;
          attempt += 1
        ) {
          await expectLater(service.pushPending(), throwsA(isA<StateError>()));
          await queue.markFailure(
            CloudSyncQueueKind.reviewEvidencePush,
            expectedOwner: 'owner-a',
          );
        }
        expect(await queue.deadLetterItems(), hasLength(1));

        final recovery = await queue.recoverDeadLetter(
          CloudSyncQueueKind.reviewEvidencePush,
        );
        expect(recovery.rearmed, isTrue);
        transport.onAppend = (events) async => [
          {
            'event_id': events.single['event_id'],
            'result': 'alreadyApplied',
            'server_sequence': 17,
          },
        ];
        await service.pushPending();
        await queue.markSuccess(
          CloudSyncQueueKind.reviewEvidencePush,
          expectedOwner: 'owner-a',
        );

        expect(
          transport.appendPayloads
              .map((payload) => payload.single['event_id'])
              .toSet(),
          {'event-a'},
        );
        expect(await service.pendingEvents(), isEmpty);
        expect(
          await isar.isarReviewEffectOutboxs
              .filter()
              .eventIdEqualTo('event-a')
              .count(),
          1,
        );
        final callsAfterAcknowledgement = transport.appendPayloads.length;
        await service.pushPending();
        expect(transport.appendPayloads, hasLength(callsAfterAcknowledgement));
      },
    );

    test(
      'interrupted acknowledgement survives store reopen and replays the same event ID',
      () async {
        final storeName =
            'evidence_reopen_${DateTime.now().microsecondsSinceEpoch}';
        await isar.close(deleteFromDisk: true);
        isar = await Isar.open(
          [
            IsarReviewEvidenceEventSchema,
            IsarReviewEffectOutboxSchema,
            CloudSyncQueueItemSchema,
          ],
          directory: tempDir.path,
          name: storeName,
        );
        await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(_event()));
        service = ReviewEvidenceSyncService(
          local: ReviewEvidenceLocalDatasource(isar),
          owner: const FixedRecordOwnerProvider('owner-a'),
          prefs: prefs,
          transport: transport,
        );
        var serverApplied = false;
        transport.onAppend = (events) async {
          final id = events.single['event_id'];
          if (!serverApplied) {
            serverApplied = true;
            await isar.close();
            return [
              {'event_id': id, 'result': 'applied', 'server_sequence': 23},
            ];
          }
          return [
            {'event_id': id, 'result': 'alreadyApplied', 'server_sequence': 23},
          ];
        };

        await expectLater(service.pushPending(), throwsA(anything));
        isar = await Isar.open(
          [
            IsarReviewEvidenceEventSchema,
            IsarReviewEffectOutboxSchema,
            CloudSyncQueueItemSchema,
          ],
          directory: tempDir.path,
          name: storeName,
        );
        service = ReviewEvidenceSyncService(
          local: ReviewEvidenceLocalDatasource(isar),
          owner: const FixedRecordOwnerProvider('owner-a'),
          prefs: prefs,
          transport: transport,
        );
        await service.pushPending();

        expect(
          transport.appendPayloads
              .map((payload) => payload.single['event_id'])
              .toList(),
          ['event-a', 'event-a'],
        );
        expect(await service.pendingEvents(), isEmpty);
        expect(
          await isar.isarReviewEffectOutboxs
              .filter()
              .eventIdEqualTo('event-a')
              .count(),
          1,
        );
        await service.pushPending();
        expect(transport.appendPayloads, hasLength(2));
      },
    );
  });
}

class _FakeEvidenceTransport implements ReviewEvidenceTransport {
  Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onAppend;
  Future<List<Map<String, dynamic>>> Function({
    required String ownerId,
    required int cursorSequence,
    required String cursorEventId,
  })?
  onPull;
  List<List<Map<String, dynamic>>> pullPages = const [];
  final pullCursors = <(int, String)>[];
  final appendPayloads = <List<Map<String, dynamic>>>[];
  var _pullIndex = 0;

  @override
  Future<List<Map<String, dynamic>>> append(List<Map<String, dynamic>> events) {
    appendPayloads.add(events);
    return onAppend?.call(events) ?? Future.value(const []);
  }

  @override
  Future<List<Map<String, dynamic>>> pull({
    required String ownerId,
    required int cursorSequence,
    required String cursorEventId,
  }) async {
    pullCursors.add((cursorSequence, cursorEventId));
    final pullHandler = onPull;
    if (pullHandler != null) {
      return pullHandler(
        ownerId: ownerId,
        cursorSequence: cursorSequence,
        cursorEventId: cursorEventId,
      );
    }
    if (_pullIndex >= pullPages.length) return const [];
    return pullPages[_pullIndex++];
  }
}

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => currentOwnerId != 'local';
}

IsarReviewEvidenceEvent _event({
  String id = 'event-a',
  String taskId = 'task-a',
}) => IsarReviewEvidenceEvent()
  ..eventId = id
  ..idempotencyKey = 'session-a|$taskId|final'
  ..sessionId = 'session-a'
  ..taskId = taskId
  ..ownerId = 'owner-a'
  ..audience = 'adult'
  ..surahId = 1
  ..ayahNumber = 1
  ..eventTypeIndex = 1
  ..assessmentIndex = 0
  ..outcomeIndex = 1
  ..ratingIndex = 2
  ..attemptCount = 1
  ..failureCount = 0
  ..hintLevelIndex = 0
  ..occurredAt = DateTime.utc(2026, 9, 14, 12)
  ..committedAt = DateTime.utc(2026, 9, 14, 12, 1)
  ..studyDayKey = '2026-09-14';

Map<String, dynamic> _cloudRow(String id, int sequence) => {
  'event_id': id,
  'user_id': 'owner-a',
  'audience': 'adult',
  'session_id': 'session-$id',
  'task_id': 'task-$id',
  'surah_id': 1,
  'ayah_number': 1,
  'event_type': 1,
  'assessment': 0,
  'outcome': 1,
  'rating': 2,
  'similarity_score': 0.5,
  'attempt_count': 1,
  'failure_count': 0,
  'hint_level': 0,
  'occurred_at': '2026-09-14T12:00:00.000Z',
  'committed_at': '2026-09-14T12:01:00.000Z',
  'study_day_key': '2026-09-14',
  'server_sequence': sequence,
};
