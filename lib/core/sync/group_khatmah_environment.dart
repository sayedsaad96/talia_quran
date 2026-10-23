import 'dart:async';
import '../../features/group_khatmah/data/group_khatmah_remote.dart';
import '../experience/experience_feature_flags.dart';
import '../identity/account_data_barrier.dart';

/// Local audience guard supplements server-owned adult eligibility.
final class GroupKhatmahAppEnvironment implements GroupKhatmahEnvironment {
  GroupKhatmahAppEnvironment({
    required this.barrier,
    required this.flags,
    required this.loadAdult,
    required this.audienceChanges,
    this.recoverPendingWake,
  });
  final AccountDataBarrier barrier;
  final ExperienceFlags flags;
  final Future<bool> Function() loadAdult;
  final Stream<void> audienceChanges;
  final Future<void> Function()? recoverPendingWake;
  final _changes = StreamController<void>.broadcast(sync: true);
  final _subscriptions = <StreamSubscription<void>>[];
  bool _adult = false, _disposed = false;
  int _revision = 0;
  AccountDataLease? _audienceLease;
  @override
  bool get featureEnabled => flags.isEnabled(ExperienceFeature.groupKhatmah);
  @override
  bool get isAdult => _adult && barrier.isReady && !_disposed;
  // The app has no connectivity observer. Online mutations preflight a remote
  // read; failure there creates no journal entry. Later failures retain IDs.
  @override
  bool get isOnline => true;
  @override
  Stream<void> get changes => _changes.stream;

  Future<void> start() async {
    if (_disposed || _subscriptions.isNotEmpty) return;
    _subscriptions.add(barrier.changes.listen((_) => _accountChanged()));
    _subscriptions.add(audienceChanges.listen((_) => unawaited(_refresh())));
    await _refresh();
  }

  void _accountChanged() {
    try {
      final lease = _audienceLease;
      if (lease != null) {
        lease.check();
        return;
      }
    } on AccountDataUnavailableException {
      // An account generation change revokes the previous audience immediately.
    }
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_disposed) return;
    final revision = ++_revision;
    _adult = false;
    _audienceLease = null;
    _changes.add(null);
    try {
      final lease = barrier.capture();
      _audienceLease = lease;
      final adult = await loadAdult().timeout(const Duration(seconds: 10));
      lease.check();
      if (_disposed || revision != _revision) return;
      _adult = adult;
      _changes.add(null);
      if (adult && featureEnabled) await recoverPendingWake?.call();
    } catch (_) {
      // Unknown audience stays unavailable; do not restore an earlier result.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _revision++;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _changes.close();
  }
}
