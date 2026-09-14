import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
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
      tempDir = await Directory.systemTemp.createTemp('talia_evidence_service_');
      isar = await Isar.open(
        [IsarReviewEvidenceEventSchema, IsarReviewEffectOutboxSchema],
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

    test('append acknowledgement clears only the event snapshot sent to the server', () async {
      final first = _event();
      final later = _event(id: 'event-b', taskId: 'task-b');
      await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(first));
      transport.onAppend = (events) async {
        await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(later));
        return const [
          {'event_id': 'event-a', 'result': 'alreadyApplied', 'server_sequence': 9},
        ];
      };

      await service.pushPending();

      final pending = await service.pendingEvents();
      expect(pending.map((event) => event.eventId), ['event-b']);
    });

    test('each reconciliation starts from zero and imports without an upload receipt', () async {
      transport.pullPages = [
        [
          _cloudRow('remote-a', 1),
          _cloudRow('remote-b', 2),
        ],
        const [],
      ];

      await service.pull();
      await service.pull();

      expect(transport.pullCursors, everyElement((cursor) => cursor.$1 == 0));
      expect(await service.pendingEvents(), isEmpty);
      expect(await isar.isarReviewEvidenceEvents.count(), 2);
    });
  });
}

class _FakeEvidenceTransport implements ReviewEvidenceTransport {
  Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)? onAppend;
  List<List<Map<String, dynamic>>> pullPages = const [];
  final pullCursors = <(int, String)>[];
  var _pullIndex = 0;

  @override
  Future<List<Map<String, dynamic>>> append(List<Map<String, dynamic>> events) =>
      onAppend?.call(events) ?? Future.value(const []);

  @override
  Future<List<Map<String, dynamic>>> pull({
    required String ownerId,
    required int cursorSequence,
    required String cursorEventId,
  }) async {
    pullCursors.add((cursorSequence, cursorEventId));
    if (_pullIndex >= pullPages.length) return const [];
    return pullPages[_pullIndex++];
  }
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
