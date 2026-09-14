import 'package:isar/isar.dart';

import '../../../../core/memorization/review_record_identity.dart';
import '../models/isar_review_effect_outbox.dart';
import '../models/isar_review_evidence_event.dart';

/// Owner-bound persistence for append-only review evidence cloud receipts.
///
/// Evidence is immutable. A processed `sync:<eventId>` receipt means the
/// exact local event was accepted by the ledger; it never changes the event.
final class ReviewEvidenceLocalDatasource {
  ReviewEvidenceLocalDatasource(this._isar, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final Isar _isar;
  final DateTime Function() _now;

  Future<void> ensureSyncEffects(String expectedOwner) async {
    if (!_isSyncableOwner(expectedOwner)) return;
    await _isar.writeTxn(() async {
      final events = await _isar.isarReviewEvidenceEvents
          .filter()
          .ownerIdEqualTo(expectedOwner)
          .findAll();
      for (final event in events) {
        final receiptKey = _receiptKey(event.eventId);
        final receipt = await _isar.isarReviewEffectOutboxs.getByReceiptKey(
          receiptKey,
        );
        if (receipt != null) {
          if (receipt.ownerId != expectedOwner ||
              receipt.eventId != event.eventId ||
              receipt.effectType != 'sync') {
            throw StateError('Evidence receipt identity conflict');
          }
          continue;
        }
        await _isar.isarReviewEffectOutboxs.put(
          IsarReviewEffectOutbox()
            ..receiptKey = receiptKey
            ..eventId = event.eventId
            ..ownerId = expectedOwner
            ..audience = event.audience
            ..effectType = 'sync'
            ..createdAt = _now().toUtc(),
        );
      }
    });
  }

  Future<List<IsarReviewEvidenceEvent>> pendingEvents(
    String expectedOwner, {
    int limit = 100,
  }) async {
    if (!_isSyncableOwner(expectedOwner) || limit <= 0) return const [];
    final effects = await _isar.isarReviewEffectOutboxs
        .filter()
        .ownerIdEqualTo(expectedOwner)
        .effectTypeEqualTo('sync')
        .processedAtIsNull()
        .findAll();
    final pendingIds = effects
        .where((effect) => effect.receiptKey == _receiptKey(effect.eventId))
        .map((effect) => effect.eventId)
        .toSet();
    if (pendingIds.isEmpty) return const [];
    final events = await _isar.isarReviewEvidenceEvents
        .filter()
        .ownerIdEqualTo(expectedOwner)
        .findAll();
    final pending = events
        .where((event) => pendingIds.contains(event.eventId))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return pending.take(limit).toList(growable: false);
  }

  Future<bool> hasUnacknowledgedEvents(String expectedOwner) async =>
      (await pendingEvents(expectedOwner, limit: 1)).isNotEmpty;

  /// Adds a complete, owner-validated pull page. Imported events receive a
  /// processed sync receipt in the same transaction so backfill never uploads
  /// them. Logical aliases preserve the existing local event and its receipt.
  Future<void> mergeCloudPage(
    String expectedOwner,
    Iterable<IsarReviewEvidenceEvent> cloudEvents,
  ) async {
    if (!_isSyncableOwner(expectedOwner)) {
      throw StateError('Cloud evidence requires an authenticated owner');
    }
    final page = cloudEvents.toList(growable: false);
    for (final event in page) {
      if (event.ownerId != expectedOwner) {
        throw StateError('Cloud evidence owner mismatch');
      }
      ReviewEvidenceWire.toRpcPayload(event);
    }
    await _isar.writeTxn(() async {
      for (final remote in page) {
        final sameId = await _isar.isarReviewEvidenceEvents.getByEventId(
          remote.eventId,
        );
        if (sameId != null) {
          if (sameId.ownerId != expectedOwner ||
              !ReviewEvidenceWire.sameImmutableEvent(sameId, remote)) {
            throw StateError('Cloud evidence event-id conflict');
          }
          continue;
        }
        final sameLogical = await _isar.isarReviewEvidenceEvents
            .getByIdempotencyKey(remote.idempotencyKey);
        if (sameLogical != null) {
          if (sameLogical.ownerId != expectedOwner ||
              !ReviewEvidenceWire.sameLogicalContent(sameLogical, remote)) {
            throw StateError('Cloud evidence logical conflict');
          }
          continue;
        }
        await _isar.isarReviewEvidenceEvents.put(remote);
        await _putProcessedReceipt(remote, expectedOwner);
      }
    });
  }

  /// Acknowledges only accepted rows from the exact request snapshot.
  Future<void> acknowledgeAccepted(
    String expectedOwner,
    Iterable<IsarReviewEvidenceEvent> sentSnapshot,
    Set<String> acceptedIds,
  ) async {
    if (!_isSyncableOwner(expectedOwner) || acceptedIds.isEmpty) return;
    final sent = {
      for (final event in sentSnapshot) event.eventId: event,
    };
    if (sent.length != sentSnapshot.length || !acceptedIds.every(sent.containsKey)) {
      throw StateError('Invalid evidence acknowledgement snapshot');
    }
    await _isar.writeTxn(() async {
      for (final eventId in acceptedIds) {
        final expected = sent[eventId]!;
        final current = await _isar.isarReviewEvidenceEvents.getByEventId(
          eventId,
        );
        if (current == null ||
            current.ownerId != expectedOwner ||
            !ReviewEvidenceWire.sameImmutableEvent(current, expected)) {
          continue;
        }
        final receipt = await _isar.isarReviewEffectOutboxs.getByReceiptKey(
          _receiptKey(eventId),
        );
        if (receipt == null ||
            receipt.ownerId != expectedOwner ||
            receipt.eventId != eventId ||
            receipt.effectType != 'sync') {
          continue;
        }
        if (receipt.processedAt == null) {
          receipt.processedAt = _now().toUtc();
          receipt.lastErrorCode = null;
          await _isar.isarReviewEffectOutboxs.put(receipt);
        }
      }
    });
  }

  Future<void> _putProcessedReceipt(
    IsarReviewEvidenceEvent event,
    String expectedOwner,
  ) async {
    final key = _receiptKey(event.eventId);
    final existing = await _isar.isarReviewEffectOutboxs.getByReceiptKey(key);
    if (existing != null) {
      if (existing.ownerId != expectedOwner || existing.eventId != event.eventId) {
        throw StateError('Cloud evidence receipt conflict');
      }
      if (existing.processedAt == null) {
        existing.processedAt = _now().toUtc();
        existing.lastErrorCode = null;
        await _isar.isarReviewEffectOutboxs.put(existing);
      }
      return;
    }
    await _isar.isarReviewEffectOutboxs.put(
      IsarReviewEffectOutbox()
        ..receiptKey = key
        ..eventId = event.eventId
        ..ownerId = expectedOwner
        ..audience = event.audience
        ..effectType = 'sync'
        ..createdAt = _now().toUtc()
        ..processedAt = _now().toUtc(),
    );
  }

  static bool _isSyncableOwner(String ownerId) =>
      ownerId.isNotEmpty && ownerId != ReviewRecordIdentity.localOwnerId;

  static String _receiptKey(String eventId) => 'sync:$eventId';
}

/// Strict mapper for the deployed review-event RPC contract.
abstract final class ReviewEvidenceWire {
  static Map<String, dynamic> toRpcPayload(IsarReviewEvidenceEvent event) {
    _validate(event);
    return {
      'event_id': event.eventId,
      'audience': event.audience,
      'session_id': event.sessionId,
      'task_id': event.taskId,
      'surah_id': event.surahId,
      'ayah_number': event.ayahNumber,
      'event_type': event.eventTypeIndex,
      'assessment': event.assessmentIndex,
      'outcome': event.outcomeIndex,
      'rating': event.ratingIndex,
      'similarity_score': _normalizedScore(event.similarityScore),
      'attempt_count': event.attemptCount,
      'failure_count': event.failureCount,
      'hint_level': event.hintLevelIndex,
      'occurred_at': event.occurredAt.toUtc().toIso8601String(),
      'study_day_key': event.studyDayKey,
    };
  }

  static Set<String> acceptedIds({
    required Iterable<IsarReviewEvidenceEvent> sentEvents,
    required Iterable<Map<String, dynamic>> responseRows,
  }) {
    final sent = {for (final event in sentEvents) event.eventId};
    if (sent.isEmpty) return const {};
    final seen = <String>{};
    final accepted = <String>{};
    for (final row in responseRows) {
      final id = row['event_id'];
      final result = row['result'];
      final sequence = row['server_sequence'];
      if (id is! String || !sent.contains(id) || !seen.add(id)) return const {};
      if (result == 'applied' || result == 'alreadyApplied') {
        if (!_isPositiveInteger(sequence)) return const {};
        accepted.add(id);
      } else if (result != 'rejected' || sequence != null) {
        return const {};
      }
    }
    return accepted;
  }

  static IsarReviewEvidenceEvent fromCloudRow(Map<String, dynamic> row) {
    final event = IsarReviewEvidenceEvent()
      ..eventId = _requiredText(row, 'event_id', 160)
      ..idempotencyKey = _idempotencyKey(row)
      ..sessionId = _requiredText(row, 'session_id', 160)
      ..taskId = _requiredText(row, 'task_id', 240)
      ..ownerId = _requiredText(row, 'user_id', 64)
      ..audience = _requiredText(row, 'audience', 5)
      ..surahId = _requiredInt(row, 'surah_id')
      ..ayahNumber = _requiredInt(row, 'ayah_number')
      ..eventTypeIndex = _requiredInt(row, 'event_type')
      ..assessmentIndex = _requiredInt(row, 'assessment')
      ..outcomeIndex = _requiredInt(row, 'outcome')
      ..ratingIndex = _optionalInt(row, 'rating')
      ..similarityScore = _optionalDouble(row, 'similarity_score')
      ..attemptCount = _requiredInt(row, 'attempt_count')
      ..failureCount = _requiredInt(row, 'failure_count')
      ..hintLevelIndex = _requiredInt(row, 'hint_level')
      ..occurredAt = _requiredDate(row, 'occurred_at')
      ..committedAt = _requiredDate(row, 'committed_at')
      ..studyDayKey = _requiredText(row, 'study_day_key', 10);
    _validate(event);
    return event;
  }

  static bool sameImmutableEvent(
    IsarReviewEvidenceEvent a,
    IsarReviewEvidenceEvent b,
  ) => a.eventId == b.eventId && sameLogicalContent(a, b);

  static bool sameLogicalContent(
    IsarReviewEvidenceEvent a,
    IsarReviewEvidenceEvent b,
  ) {
    final left = toRpcPayload(a)..remove('event_id');
    final right = toRpcPayload(b)..remove('event_id');
    if (left.length != right.length) return false;
    return left.entries.every((entry) => right[entry.key] == entry.value);
  }

  static void _validate(IsarReviewEvidenceEvent event) {
    if (!_validText(event.eventId, 160) ||
        !_validText(event.sessionId, 160) ||
        !_validText(event.taskId, 240) ||
        (event.audience != 'adult' && event.audience != 'kids') ||
        !_validAyah(event.surahId, event.ayahNumber) ||
        event.eventTypeIndex < 0 || event.eventTypeIndex > 1 ||
        event.assessmentIndex < 0 || event.assessmentIndex > 1 ||
        event.outcomeIndex < 0 || event.outcomeIndex > 2 ||
        (event.ratingIndex != null &&
            (event.ratingIndex! < 0 || event.ratingIndex! > 2)) ||
        event.attemptCount < 1 || event.attemptCount > 1000 ||
        event.failureCount < 0 || event.failureCount > event.attemptCount ||
        event.hintLevelIndex < 0 || event.hintLevelIndex > 2 ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(event.studyDayKey) ||
        (event.similarityScore != null &&
            (!event.similarityScore!.isFinite ||
                event.similarityScore! < 0 ||
                event.similarityScore! > 1))) {
      throw const FormatException('Invalid review evidence event');
    }
  }

  static String _idempotencyKey(Map<String, dynamic> row) {
    final session = _requiredText(row, 'session_id', 160);
    final task = _requiredText(row, 'task_id', 240);
    final type = _requiredInt(row, 'event_type');
    final attempt = _requiredInt(row, 'attempt_count');
    return type == ReviewEvidenceEventType.finalOutcome.index
        ? '$session|$task|final'
        : '$session|$task|attempt:$attempt';
  }

  static String _requiredText(Map<String, dynamic> row, String key, int max) {
    final value = row[key];
    if (value is! String || !_validText(value, max)) {
      throw FormatException('Invalid $key');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (!_isInteger(value)) throw FormatException('Invalid $key');
    return (value as num).toInt();
  }

  static int? _optionalInt(Map<String, dynamic> row, String key) =>
      row[key] == null ? null : _requiredInt(row, key);

  static double? _optionalDouble(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return null;
    if (value is! num || !value.isFinite) throw FormatException('Invalid $key');
    return _normalizedScore(value.toDouble());
  }

  static DateTime _requiredDate(Map<String, dynamic> row, String key) {
    final value = row[key];
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) throw FormatException('Invalid $key');
    return parsed.toUtc();
  }

  static bool _validText(String value, int max) =>
      value.isNotEmpty && value.length <= max;

  static bool _isInteger(Object? value) =>
      value is num && value.isFinite && value == value.roundToDouble();

  static bool _isPositiveInteger(Object? value) =>
      _isInteger(value) && (value as num) > 0;

  static double? _normalizedScore(double? value) => value == null
      ? null
      : (value * 10000).roundToDouble() / 10000;

  static bool _validAyah(int surah, int ayah) =>
      surah >= 1 && surah <= _ayahCounts.length && ayah >= 1 && ayah <= _ayahCounts[surah - 1];

  static const _ayahCounts = <int>[
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52,
    99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88,
    69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53,
    89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96,
    29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25,
    22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8,
    8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4,
    5, 6,
  ];
}
