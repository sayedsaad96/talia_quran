import 'dart:async';
import 'dart:convert';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../utils/talia_logger.dart';
import 'widget_snapshot.dart';

abstract interface class HomeWidgetBridge {
  Future<void> save(String key, String? json);
  Future<void> requestUpdate();
}

typedef WidgetSnapshotLoader =
    Future<WidgetSnapshot> Function(AccountDataLease lease, String ownerId);

/// The foreground isolate is the sole writer. Background work only redraws.
final class HomeWidgetPublisher {
  HomeWidgetPublisher({
    required this.bridge,
    required this.load,
    required this.owner,
    required this.barrier,
    this.authorityChanges = const [],
    this.refreshTriggers = const [],
  });
  static const snapshotKey = 'talia_widget_snapshot_v1';
  final HomeWidgetBridge bridge;
  final WidgetSnapshotLoader load;
  final RecordOwnerProvider owner;
  final AccountDataBarrier barrier;
  final List<Stream<void>> authorityChanges;
  final List<Stream<void>> refreshTriggers;
  final _subscriptions = <StreamSubscription<void>>[];
  Future<void> _tail = Future.value();
  Future<void> _lastClear = Future.value();
  bool _ready = false, _disposed = false, _started = false;
  int _revision = 0, _clearRevision = 0;
  void Function()? _removeInvalidationParticipant;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _removeInvalidationParticipant = barrier.addInvalidationParticipant(
      clearForAccountTransition,
    );
    _subscriptions.add(
      barrier.changes.listen((_) {
        if (barrier.isReady) {
          unawaited(refresh());
        }
      }),
    );
    for (final changes in authorityChanges) {
      _subscriptions.add(changes.listen((_) => unawaited(_resetAudience())));
    }
    for (final changes in refreshTriggers) {
      _subscriptions.add(changes.listen((_) => unawaited(refresh())));
    }
    await clear();
  }

  Future<void> _resetAudience() async {
    await clear();
    if (_ready) await refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final revision = ++_revision;
    try {
      await _lastClear;
      if (!_current(revision)) return;
      if (!_ready || !owner.isSignedIn || !barrier.isReady) {
        await clear();
        return;
      }
      final ownerId = owner.currentOwnerId;
      final lease = barrier.capture();
      lease.checkOwner(ownerId);
      final snapshot = await load(
        lease,
        ownerId,
      ).timeout(const Duration(seconds: 15));
      if (!_authorized(revision, lease, ownerId)) return;
      await _enqueue(() async {
        if (!_authorized(revision, lease, ownerId)) return;
        await bridge.save(
          snapshotKey,
          snapshot.isEmpty ? null : jsonEncode(snapshot.toJson()),
        );
        await bridge.requestUpdate();
      });
    } catch (error, stack) {
      TaliaLogger.w('Home widget refresh failed', error, stack);
      if (_current(revision)) await clear();
    }
  }

  bool _current(int revision) => !_disposed && revision == _revision;

  bool _authorized(int revision, AccountDataLease lease, String ownerId) {
    if (!_current(revision) || !_ready || !owner.isSignedIn) return false;
    try {
      lease.checkOwner(ownerId);
      return true;
    } on AccountDataUnavailableException {
      return false;
    }
  }

  /// Transition callers await this acknowledgement before activating an owner.
  /// No native operation is timed out: late writes must stay ahead of clear.
  Future<void> clearForAccountTransition() {
    _revision++;
    final clearRevision = ++_clearRevision;
    _ready = false;
    final clearing = _enqueue(() async {
      await bridge.save(snapshotKey, null);
      await bridge.requestUpdate();
      if (clearRevision == _clearRevision) _ready = true;
    });
    _lastClear = clearing;
    return clearing;
  }

  Future<void> clear() async {
    try {
      await clearForAccountTransition();
    } catch (error, stack) {
      TaliaLogger.w(
        'Home widget clear failed; publication blocked',
        error,
        stack,
      );
    }
  }

  Future<void> _enqueue(Future<void> Function() work) {
    final operation = _tail.then((_) => work());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  Future<void> dispose() async {
    _disposed = true;
    _removeInvalidationParticipant?.call();
    _revision++;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await clear();
  }
}
