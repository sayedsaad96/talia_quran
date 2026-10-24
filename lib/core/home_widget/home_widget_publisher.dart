import 'dart:async';
import 'dart:convert';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../utils/talia_logger.dart';
import 'widget_snapshot.dart';

abstract interface class HomeWidgetBridge {
  Future<void> save(String key, String? json);
  Future<void> requestUpdate();

  /// Replaces the native redraw alarms (prayer times and snapshot expiry).
  Future<void> scheduleUpdates(List<DateTime> times);
  Future<void> cancelScheduledUpdates();

  /// Enables or disables the manifest receiver so the widget is only offered
  /// to the user while its feature flag is on.
  Future<void> setReceiverEnabled(bool enabled);
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
    this.flagChanges = const [],
    this.isEnabled = _alwaysEnabled,
    this.audience,
    this.clearTimeout = const Duration(seconds: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  static const snapshotKey = 'talia_widget_snapshot_v1';
  static bool _alwaysEnabled() => true;
  final HomeWidgetBridge bridge;
  final WidgetSnapshotLoader load;
  final RecordOwnerProvider owner;
  final AccountDataBarrier barrier;
  final List<Stream<void>> authorityChanges;
  final List<Stream<void>> refreshTriggers;

  /// Emits when the feature flag may have changed.
  final List<Stream<void>> flagChanges;
  final bool Function() isEnabled;

  /// Identifies the audience (for example adult or kids) of the current owner.
  /// An authority change with an unchanged owner and audience refreshes in
  /// place instead of blanking the widget. Null keeps clear-first behavior.
  final Future<Object?> Function()? audience;

  /// Bound on each native clear acknowledgement. The clear itself stays queued
  /// behind any in-flight write, so ordering is preserved after a timeout.
  final Duration clearTimeout;
  final DateTime Function() _now;
  final _subscriptions = <StreamSubscription<void>>[];
  Future<void> _tail = Future.value();
  Future<void> _lastClear = Future.value();
  Future<void>? _running;
  bool _ready = false, _disposed = false, _started = false;
  bool _flagEnabled = true, _rerun = false;
  int _revision = 0, _clearRevision = 0, _runningRevision = -1, _loopSeq = 0;
  String? _audience;
  void Function()? _removeInvalidationParticipant;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _flagEnabled = isEnabled();
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
    for (final changes in flagChanges) {
      _subscriptions.add(changes.listen((_) => unawaited(_onFlagChanged())));
    }
    if (_flagEnabled) {
      await clear();
      await _applyReceiver(true);
    } else {
      // Disabled builds must never wait on native code during startup.
      unawaited(_startDisabled());
    }
  }

  Future<void> _startDisabled() async {
    await clear();
    await _applyReceiver(false);
  }

  Future<void> _onFlagChanged() async {
    await _syncFlag();
    if (_flagEnabled) await refresh();
  }

  /// Applies a flag transition: off clears and disables the receiver, on
  /// enables it (a refresh then repopulates).
  Future<void> _syncFlag() async {
    if (_disposed) return;
    final enabled = isEnabled();
    if (enabled == _flagEnabled) return;
    _flagEnabled = enabled;
    if (enabled) {
      await _applyReceiver(true);
    } else {
      await clear();
      await _applyReceiver(false);
    }
  }

  Future<void> _applyReceiver(bool enabled) async {
    try {
      await bridge.setReceiverEnabled(enabled).timeout(clearTimeout);
    } catch (error, stack) {
      TaliaLogger.w('Home widget receiver state change failed', error, stack);
    }
  }

  Future<void> _resetAudience() async {
    final next = await _audienceKey(owner.currentOwnerId);
    if (next != null && next == _audience && _ready && barrier.isReady) {
      await refresh();
      return;
    }
    await clear();
    if (_ready) await refresh();
  }

  Future<String?> _audienceKey(String ownerId) async {
    final provider = audience;
    if (provider == null) return null;
    try {
      return '$ownerId|${await provider()}';
    } catch (_) {
      return null;
    }
  }

  /// Concurrent requests collapse into the running refresh plus one trailing
  /// run, so a resume and a schedule update do not both read everything.
  Future<void> refresh() {
    if (_disposed) return Future.value();
    final running = _running;
    if (running != null && _runningRevision == _revision) {
      _rerun = true;
      return running;
    }
    final id = ++_loopSeq;
    late final Future<void> loop;
    loop = _refreshLoop(id).whenComplete(() {
      if (identical(_running, loop)) _running = null;
    });
    _running = loop;
    return loop;
  }

  Future<void> _refreshLoop(int id) async {
    do {
      _rerun = false;
      await _refreshOnce();
    } while (_rerun && !_disposed && id == _loopSeq);
  }

  Future<void> _refreshOnce() async {
    if (_disposed) return;
    var revision = ++_revision;
    _runningRevision = revision;
    try {
      if (isEnabled() != _flagEnabled) {
        await _syncFlag();
        revision = ++_revision;
        _runningRevision = revision;
      }
      if (!_flagEnabled) return;
      await _lastClear;
      if (!_current(revision)) return;
      if (!_ready || !barrier.isReady) {
        await clear();
        return;
      }
      final ownerId = owner.currentOwnerId;
      final lease = barrier.capture();
      lease.checkOwner(ownerId);
      final audienceKey = await _audienceKey(ownerId);
      final snapshot = await load(
        lease,
        ownerId,
      ).timeout(const Duration(seconds: 15));
      if (!_authorized(revision, lease, ownerId)) return;
      await _enqueue(() async {
        if (!_authorized(revision, lease, ownerId)) return;
        await bridge.save(
          snapshotKey,
          snapshot.clearsNative ? null : jsonEncode(snapshot.toJson()),
        );
        await bridge.requestUpdate();
        _audience = audienceKey;
        await _scheduleRedraws(snapshot);
      });
    } catch (error, stack) {
      TaliaLogger.w('Home widget refresh failed', error, stack);
      if (_current(revision)) await clear();
    }
  }

  /// Best effort: the snapshot is already saved and drawn, so a scheduling
  /// failure only costs the timed redraws (the next refresh retries).
  Future<void> _scheduleRedraws(WidgetSnapshot snapshot) async {
    try {
      final times = snapshot.clearsNative
          ? const <DateTime>[]
          : snapshot.redrawTimes(_now());
      if (times.isEmpty) {
        await bridge.cancelScheduledUpdates();
      } else {
        await bridge.scheduleUpdates(times);
      }
    } catch (error, stack) {
      TaliaLogger.w('Home widget redraw scheduling failed', error, stack);
    }
  }

  bool _current(int revision) => !_disposed && revision == _revision;

  bool _authorized(int revision, AccountDataLease lease, String ownerId) {
    if (!_current(revision) || !_ready) return false;
    try {
      lease.checkOwner(ownerId);
      return true;
    } on AccountDataUnavailableException {
      return false;
    }
  }

  /// Transition callers await this acknowledgement before activating an owner.
  /// Each attempt is bounded by [clearTimeout] and retried once, but the clear
  /// stays queued behind an in-flight write so a late write can never land
  /// after it. A clear that cannot be acknowledged throws and keeps the owner
  /// blocked.
  Future<void> clearForAccountTransition() {
    _revision++;
    final clearRevision = ++_clearRevision;
    _ready = false;
    _audience = null;
    Future<void> attempt() => _enqueue(() async {
      await bridge.save(snapshotKey, null);
      await bridge.requestUpdate();
      try {
        await bridge.cancelScheduledUpdates();
      } catch (error, stack) {
        TaliaLogger.w('Home widget alarm cancel failed', error, stack);
      }
      if (clearRevision == _clearRevision) _ready = true;
    }).timeout(clearTimeout);
    final result = _clearWithRetry(attempt);
    _lastClear = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _clearWithRetry(Future<void> Function() attempt) async {
    try {
      await attempt();
    } catch (error, stack) {
      TaliaLogger.w('Home widget clear failed; retrying once', error, stack);
      await attempt();
    }
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
