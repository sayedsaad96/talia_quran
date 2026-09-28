import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/identity/account_data_barrier.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/memorization/cloud_sync_feature_flags.dart';
import '../../../../../core/utils/talia_logger.dart';
import '../../datasources/review_evidence_local_datasource.dart';
import '../../models/isar_review_evidence_event.dart';
import 'memorization_cloud_gateway.dart';

abstract interface class ReviewEvidenceTransport {
  Future<List<Map<String, dynamic>>> append(List<Map<String, dynamic>> events);

  Future<List<Map<String, dynamic>>> pull({
    required String ownerId,
    required int cursorSequence,
    required String cursorEventId,
  });
}

abstract interface class ReviewEvidenceSync {
  bool get isEnabled;
  Future<void> pull();
  Future<void> pushPending();
  Future<bool> flushPending();
  Future<bool> hasUnacknowledgedEvents();
}

/// Supabase implementation kept behind the small transport boundary so retry
/// and storage behavior can use hand-written fakes in tests.
final class SupabaseReviewEvidenceTransport implements ReviewEvidenceTransport {
  SupabaseReviewEvidenceTransport(this._gateway);

  final MemorizationCloudGateway _gateway;

  SupabaseClient get _client => _gateway.supabase;

  @override
  Future<List<Map<String, dynamic>>> append(
    List<Map<String, dynamic>> events,
  ) async {
    final raw = await _client.rpc(
      'append_ayah_review_events_v1',
      params: {'p_events': events},
    );
    return _mapRows(raw);
  }

  @override
  Future<List<Map<String, dynamic>>> pull({
    required String ownerId,
    required int cursorSequence,
    required String cursorEventId,
  }) async {
    final raw = await _client.rpc(
      'pull_ayah_review_events_since',
      params: {
        'p_owner_user_id': ownerId,
        'p_cursor_sequence': cursorSequence,
        'p_cursor_event_id': cursorEventId,
        'p_limit': 500,
      },
    );
    return _mapRows(raw);
  }

  static List<Map<String, dynamic>> _mapRows(Object? raw) {
    if (raw is! List) {
      throw const FormatException('Invalid evidence RPC response');
    }
    return raw
        .map((row) {
          if (row is! Map) {
            throw const FormatException('Invalid evidence RPC row');
          }
          return Map<String, dynamic>.from(row);
        })
        .toList(growable: false);
  }
}

/// Safe reconciliation for immutable review evidence.
///
/// The deployed sequence is allocated before transaction commit, so a lower
/// sequence can become visible after a higher one. A strict high-water cursor
/// could therefore miss a late commit forever. Instead (S-2):
/// * a full reconciliation from zero runs at least every
///   [fullReconcileInterval] (and on the first pull);
/// * in between, pulls resume [overlapSequences] below the highest sequence
///   seen, re-reading a window wide enough for late commits. Merging is
///   idempotent, so the overlap costs only bandwidth.
final class ReviewEvidenceSyncService implements ReviewEvidenceSync {
  ReviewEvidenceSyncService({
    required ReviewEvidenceLocalDatasource local,
    required RecordOwnerProvider owner,
    required SharedPreferences prefs,
    required ReviewEvidenceTransport transport,
    AccountDataBarrier? barrier,
    DateTime Function()? now,
  }) : _local = local,
       _owner = owner,
       _prefs = prefs,
       _transport = transport,
       _barrier = barrier ?? AccountDataBarrier.forPreferences(prefs),
       _now = now ?? DateTime.now;

  static const int overlapSequences = 1000;
  static const Duration fullReconcileInterval = Duration(hours: 24);

  final ReviewEvidenceLocalDatasource _local;
  final RecordOwnerProvider _owner;
  final SharedPreferences _prefs;
  final ReviewEvidenceTransport _transport;
  final AccountDataBarrier _barrier;
  final DateTime Function() _now;

  String _highWaterKey(String owner) => 'review_evidence_pull_hw_$owner';
  String _fullPullKey(String owner) => 'review_evidence_full_pull_at_$owner';

  /// Where this pull starts: zero for a (periodic) full reconciliation,
  /// otherwise the overlap window below the highest sequence seen.
  (int, bool) _pullStart(String owner) {
    final lastFullRaw = _prefs.getString(_fullPullKey(owner));
    final lastFull = lastFullRaw == null
        ? null
        : DateTime.tryParse(lastFullRaw);
    final highWater = _prefs.getInt(_highWaterKey(owner));
    if (lastFull == null ||
        highWater == null ||
        _now().toUtc().difference(lastFull.toUtc()) >= fullReconcileInterval) {
      return (0, true);
    }
    final start = highWater - overlapSequences;
    return (start < 0 ? 0 : start, false);
  }

  @override
  bool get isEnabled =>
      CloudSyncFeatureFlags.isReviewEvidenceTransportEnabled(_prefs);

  Future<List<IsarReviewEvidenceEvent>> pendingEvents() async {
    final ownerId = _owner.currentOwnerId;
    if (!_owner.isSignedIn) return const [];
    final lease = _barrier.capture();
    await _barrier.run(
      (_) => _local.ensureSyncEffects(ownerId),
      authority: lease,
    );
    lease.check();
    _ensureOwner(ownerId);
    return _local.pendingEvents(ownerId);
  }

  @override
  Future<bool> hasUnacknowledgedEvents() async =>
      (await pendingEvents()).isNotEmpty;

  /// Appends a snapshot. A receipt is not cleared until the response names the
  /// exact sent event ID as applied/alreadyApplied with a valid sequence.
  @override
  Future<void> pushPending() async {
    if (!isEnabled || !_owner.isSignedIn) return;
    final expectedOwner = _owner.currentOwnerId;
    final lease = _barrier.capture();
    await _barrier.run(
      (_) => _local.ensureSyncEffects(expectedOwner),
      authority: lease,
    );
    lease.check();
    _ensureOwner(expectedOwner);

    final pending = await _local.pendingEvents(expectedOwner);
    if (pending.isEmpty) return;
    lease.check();
    _ensureOwner(expectedOwner);
    final batch = _boundedBatch(pending);
    if (batch.isEmpty) return;
    final payload = batch.map(ReviewEvidenceWire.toRpcPayload).toList();
    lease.check();
    _ensureOwner(expectedOwner);
    final response = await _transport.append(payload);
    lease.check();
    _ensureOwner(expectedOwner);
    final accepted = ReviewEvidenceWire.acceptedIds(
      sentEvents: batch,
      responseRows: response,
    );
    await _barrier.run(
      (_) => _local.acknowledgeAccepted(expectedOwner, batch, accepted),
      authority: lease,
    );
    lease.check();
    _ensureOwner(expectedOwner);
  }

  /// Drains bounded append batches for an explicit lifecycle flush. A rejected
  /// or disabled batch cannot spin forever: the remaining first ID proves that
  /// no progress was made and the caller keeps account data instead.
  @override
  Future<bool> flushPending({int maxBatches = 20}) async {
    if (!_owner.isSignedIn) return true;
    for (var batch = 0; batch < maxBatches; batch += 1) {
      final before = await pendingEvents();
      if (before.isEmpty) return true;
      if (!isEnabled) return false;
      final firstId = before.first.eventId;
      await pushPending();
      final after = await pendingEvents();
      if (after.isEmpty) return true;
      if (after.first.eventId == firstId) return false;
    }
    return (await pendingEvents()).isEmpty;
  }

  /// Reconciles every page from zero. It does not persist server sequence as a
  /// completion cursor, preventing loss when lower allocated sequences commit
  /// after a later sequence becomes visible.
  @override
  Future<void> pull() async {
    if (!isEnabled || !_owner.isSignedIn) return;
    final expectedOwner = _owner.currentOwnerId;
    final lease = _barrier.capture();
    final (startSequence, isFull) = _pullStart(expectedOwner);
    var cursorSequence = startSequence;
    var cursorEventId = '';
    var highest = _prefs.getInt(_highWaterKey(expectedOwner)) ?? 0;
    Future<void> complete() async {
      await _prefs.setInt(_highWaterKey(expectedOwner), highest);
      if (isFull) {
        await _prefs.setString(
          _fullPullKey(expectedOwner),
          _now().toUtc().toIso8601String(),
        );
      }
    }

    while (true) {
      lease.check();
      _ensureOwner(expectedOwner);
      final rows = await _transport.pull(
        ownerId: expectedOwner,
        cursorSequence: cursorSequence,
        cursorEventId: cursorEventId,
      );
      lease.check();
      _ensureOwner(expectedOwner);
      if (rows.length > 500) {
        throw const FormatException('Evidence pull page exceeds server limit');
      }
      if (rows.isEmpty) return complete();
      var previousCursor = (cursorSequence, cursorEventId);
      for (final row in rows) {
        final rowCursor = _pageCursor(row);
        if (rowCursor.$1 < previousCursor.$1 ||
            (rowCursor.$1 == previousCursor.$1 &&
                rowCursor.$2.compareTo(previousCursor.$2) <= 0)) {
          throw const FormatException('Evidence pull page is not ordered');
        }
        previousCursor = rowCursor;
      }
      final events = rows.map(ReviewEvidenceWire.fromCloudRow).toList();
      if (events.any((event) => event.ownerId != expectedOwner)) {
        throw StateError('Evidence pull owner mismatch');
      }
      final last = previousCursor;
      await _barrier.run(
        (_) => _local.mergeCloudPage(expectedOwner, events),
        authority: lease,
      );
      lease.check();
      _ensureOwner(expectedOwner);
      cursorSequence = last.$1;
      cursorEventId = last.$2;
      if (last.$1 > highest) highest = last.$1;
      if (rows.length < 500) return complete();
    }
  }

  /// Up to 100 events within the payload budget. An event that is invalid or
  /// alone exceeds the budget is skipped, not thrown (S-3): it stays pending
  /// locally (never deleted) instead of blocking every later upload.
  List<IsarReviewEvidenceEvent> _boundedBatch(
    List<IsarReviewEvidenceEvent> pending,
  ) {
    const budget = 240 * 1024;
    final batch = <IsarReviewEvidenceEvent>[];
    var bytes = 2; // []
    for (final event in pending) {
      if (batch.length >= 100) break;
      final int size;
      try {
        size = utf8
            .encode(jsonEncode(ReviewEvidenceWire.toRpcPayload(event)))
            .length;
      } on FormatException catch (error, stack) {
        TaliaLogger.w('Skipping invalid review evidence event', error, stack);
        continue;
      }
      final additional = size + (batch.isEmpty ? 0 : 1);
      if (2 + size > budget) {
        TaliaLogger.w('Skipping review evidence event over payload budget');
        continue;
      }
      if (bytes + additional > budget) break;
      batch.add(event);
      bytes += additional;
    }
    return batch;
  }

  (int, String) _pageCursor(Map<String, dynamic> row) {
    final sequence = row['server_sequence'];
    final eventId = row['event_id'];
    if (sequence is! num ||
        !sequence.isFinite ||
        sequence != sequence.roundToDouble() ||
        sequence <= 0 ||
        eventId is! String ||
        eventId.isEmpty) {
      throw const FormatException('Invalid evidence pull cursor');
    }
    return (sequence.toInt(), eventId);
  }

  void _ensureOwner(String expectedOwner) {
    if (!_owner.isSignedIn || _owner.currentOwnerId != expectedOwner) {
      throw const AccountDataUnavailableException();
    }
  }
}
