import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/identity/account_data_barrier.dart';
import '../../../../../core/identity/record_owner_provider.dart';
import '../../../../../core/memorization/cloud_sync_feature_flags.dart';
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
  Future<void> pull();
  Future<void> pushPending();
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
    if (raw is! List) throw const FormatException('Invalid evidence RPC response');
    return raw.map((row) {
      if (row is! Map) throw const FormatException('Invalid evidence RPC row');
      return Map<String, dynamic>.from(row);
    }).toList(growable: false);
  }
}

/// Safe, full-history reconciliation for immutable review evidence.
///
/// The deployed sequence is allocated before transaction commit, so successful
/// runs intentionally restart at sequence zero instead of storing a permanent
/// high-water mark that could miss a late commit.
final class ReviewEvidenceSyncService implements ReviewEvidenceSync {
  ReviewEvidenceSyncService({
    required ReviewEvidenceLocalDatasource local,
    required RecordOwnerProvider owner,
    required SharedPreferences prefs,
    required ReviewEvidenceTransport transport,
    AccountDataBarrier? barrier,
  }) : _local = local,
       _owner = owner,
       _prefs = prefs,
       _transport = transport,
       _barrier = barrier ?? AccountDataBarrier.forPreferences(prefs);

  final ReviewEvidenceLocalDatasource _local;
  final RecordOwnerProvider _owner;
  final SharedPreferences _prefs;
  final ReviewEvidenceTransport _transport;
  final AccountDataBarrier _barrier;

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
    final batch = _boundedBatch(pending);
    final payload = batch.map(ReviewEvidenceWire.toRpcPayload).toList();
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

  /// Reconciles every page from zero. It does not persist server sequence as a
  /// completion cursor, preventing loss when lower allocated sequences commit
  /// after a later sequence becomes visible.
  @override
  Future<void> pull() async {
    if (!isEnabled || !_owner.isSignedIn) return;
    final expectedOwner = _owner.currentOwnerId;
    final lease = _barrier.capture();
    var cursorSequence = 0;
    var cursorEventId = '';
    while (true) {
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
      if (rows.isEmpty) return;
      final events = rows.map(ReviewEvidenceWire.fromCloudRow).toList();
      if (events.any((event) => event.ownerId != expectedOwner)) {
        throw StateError('Evidence pull owner mismatch');
      }
      final last = _pageCursor(rows.last);
      if (last.$1 < cursorSequence ||
          (last.$1 == cursorSequence && last.$2.compareTo(cursorEventId) <= 0)) {
        throw const FormatException('Evidence pull cursor did not advance');
      }
      await _barrier.run(
        (_) => _local.mergeCloudPage(expectedOwner, events),
        authority: lease,
      );
      lease.check();
      _ensureOwner(expectedOwner);
      cursorSequence = last.$1;
      cursorEventId = last.$2;
      if (rows.length < 500) return;
    }
  }

  List<IsarReviewEvidenceEvent> _boundedBatch(
    List<IsarReviewEvidenceEvent> pending,
  ) {
    final batch = <IsarReviewEvidenceEvent>[];
    var bytes = 2; // []
    for (final event in pending.take(100)) {
      final encoded = jsonEncode(ReviewEvidenceWire.toRpcPayload(event));
      final additional = utf8.encode(encoded).length + (batch.isEmpty ? 0 : 1);
      if (batch.isNotEmpty && bytes + additional > 240 * 1024) break;
      if (batch.isEmpty && bytes + additional > 240 * 1024) {
        throw const FormatException('Evidence event exceeds payload budget');
      }
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
