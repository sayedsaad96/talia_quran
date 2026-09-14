import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/review_evidence_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';

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
  group('ReviewEvidenceLocalDatasource', () {
    late Directory tempDir;
    late Isar isar;
    late ReviewEvidenceLocalDatasource datasource;

    setUp(() async {
      await _initializeIsarCoreForTests();
      tempDir = await Directory.systemTemp.createTemp('talia_evidence_sync_');
      isar = await Isar.open(
        [IsarReviewEvidenceEventSchema, IsarReviewEffectOutboxSchema],
        directory: tempDir.path,
        name: 'evidence_${DateTime.now().microsecondsSinceEpoch}',
      );
      datasource = ReviewEvidenceLocalDatasource(isar);
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('backfills an unsynced owner event and serializes only RPC fields', () async {
      await isar.writeTxn(() => isar.isarReviewEvidenceEvents.put(_event()));

      await datasource.ensureSyncEffects('owner-a');
      final pending = await datasource.pendingEvents('owner-a');

      expect(pending.single.eventId, 'event-a');
      expect(
        ReviewEvidenceWire.toRpcPayload(pending.single),
        {
          'event_id': 'event-a',
          'audience': 'adult',
          'session_id': 'session-a',
          'task_id': 'task-a',
          'surah_id': 1,
          'ayah_number': 1,
          'event_type': 1,
          'assessment': 0,
          'outcome': 1,
          'rating': 2,
          'similarity_score': 0.1235,
          'attempt_count': 1,
          'failure_count': 0,
          'hint_level': 0,
          'occurred_at': '2026-09-14T12:00:00.000Z',
          'study_day_key': '2026-09-14',
        },
      );
    });

    test('acknowledges only accepted sent IDs without clearing a sibling receipt', () async {
      await isar.writeTxn(() async {
        await isar.isarReviewEvidenceEvents.putAll([
          _event(),
          _event(id: 'event-b', taskId: 'task-b'),
        ]);
      });
      await datasource.ensureSyncEffects('owner-a');

      final accepted = ReviewEvidenceWire.acceptedIds(
        sentEvents: [_event()],
        responseRows: const [
          {'event_id': 'event-a', 'result': 'applied', 'server_sequence': 7},
        ],
      );
      await datasource.acknowledgeAccepted('owner-a', [_event()], accepted);

      final effects = await isar.isarReviewEffectOutboxs.where().findAll();
      expect(
        effects.singleWhere((effect) => effect.eventId == 'event-a').processedAt,
        isNotNull,
      );
      expect(
        effects.singleWhere((effect) => effect.eventId == 'event-b').processedAt,
        isNull,
      );
    });

    test('merged cloud event receives a completed receipt and is never re-uploaded', () async {
      await datasource.mergeCloudPage('owner-a', [_event(id: 'remote-event')]);

      expect(await datasource.pendingEvents('owner-a'), isEmpty);
      final effect = await isar.isarReviewEffectOutboxs
          .filter()
          .eventIdEqualTo('remote-event')
          .findFirst();
      expect(effect?.processedAt, isNotNull);
    });
  });
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
  ..eventTypeIndex = ReviewEvidenceEventType.finalOutcome.index
  ..assessmentIndex = ReviewEvidenceAssessment.automatic.index
  ..outcomeIndex = ReviewEvidenceOutcome.passed.index
  ..ratingIndex = 2
  ..similarityScore = 0.123456
  ..attemptCount = 1
  ..failureCount = 0
  ..hintLevelIndex = 0
  ..occurredAt = DateTime.utc(2026, 9, 14, 12)
  ..committedAt = DateTime.utc(2026, 9, 14, 12, 1)
  ..studyDayKey = '2026-09-14';
