import 'dart:async';

import 'package:flutter/services.dart';

import '../data/datasources/share_good_local_store.dart';
import '../domain/entities/invite_activity_target.dart';
import '../domain/entities/invite_types.dart';

class ActiveInviteSessions {
  ActiveInviteSessions(this._local);
  final ShareGoodLocalStore _local;
  final _sessions = <String, InviteSession>{};
  final _touched = <String>{};
  bool _restoring = false;
  final _changes = StreamController<InviteSession>.broadcast();
  Stream<InviteSession> get changes => _changes.stream;

  Future<void> restore() async {
    if (_restoring || _changes.isClosed) return;
    _restoring = true;
    try {
      for (final session in await _local.eligibleStartedSessions()) {
        if (_changes.isClosed) return;
        if (!_touched.contains(session.token)) activate(session);
      }
    } on PlatformException {
      // Storage may be temporarily unavailable; leave the registry empty.
    } on FormatException {
      // Corrupt storage must not restore an unverified session.
    } finally {
      _restoring = false;
      _touched.clear();
    }
  }

  void activate(InviteSession session) {
    if (_restoring) _touched.add(session.token);
    final status = [
      session.serverStatus?.index ?? -1,
      session.pendingStatus?.index ?? -1,
    ];
    if (_changes.isClosed ||
        session.snapshot.status != InviteLifecycleStatus.active ||
        !session.snapshot.expiresAt.isAfter(DateTime.now()) ||
        status.any(
          (value) => value >= InviteParticipationStatus.completedPrivate.index,
        ) ||
        !status.contains(InviteParticipationStatus.started.index)) {
      return;
    }
    _sessions[session.token] = session;
    _changes.add(session);
  }

  InviteSession? forTarget(InviteActivityTarget target) {
    for (final session in _sessions.values.toList().reversed) {
      if (session.snapshot.target == target &&
          session.snapshot.status == InviteLifecycleStatus.active &&
          session.snapshot.expiresAt.isAfter(DateTime.now())) {
        return session;
      }
    }
    return null;
  }

  InviteSession? forLocalSessionId(String id) => _sessions.values
      .where((session) => session.localSessionId == id)
      .firstOrNull;

  void clear(String token) {
    if (_restoring) _touched.add(token);
    final removed = _sessions.remove(token);
    if (removed != null && !_changes.isClosed) _changes.add(removed);
  }

  Future<void> dispose() => _changes.close();
}
