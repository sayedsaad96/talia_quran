import 'dart:async';
import '../../../../core/utils/talia_logger.dart';
import '../data/datasources/share_good_local_store.dart';
import '../domain/entities/invite_types.dart';
import 'active_invite_sessions.dart';

/// Claims only opaque notification identifiers; bearer tokens remain in secure storage.
class ShareGoodNotificationController {
  ShareGoodNotificationController({
    required this.store,
    required this.isAvailable,
    required this.isAdult,
    required this.reminderEnabled,
  });
  final ShareGoodLocalStore store;
  final bool Function() isAvailable;
  final Future<bool> Function() isAdult;
  final bool Function() reminderEnabled;
  final Set<String> _claimed = {};
  StreamSubscription<InviteSession>? _subscription;
  StreamSubscription<void>? _audienceSubscription;
  Future<void> Function()? _refreshImpl;
  Future<void> _tail = Future.value();
  Timer? _expiry;
  String? _scheduledId;
  bool _disposed = false;
  static final _payloadPattern = RegExp(r'^sg1\|([A-Za-z0-9_-]{24})$');

  Future<InviteSession?> claim(String? payload) async {
    final id = payload == null
        ? null
        : _payloadPattern.firstMatch(payload)?.group(1);
    if (id == null || !_claimed.add(id)) return null;
    try {
      if (!isAvailable() || !reminderEnabled() || !await isAdult()) return null;
      final session = await store.sessionByLocalId(id);
      if (session == null ||
          session.localSessionId != id ||
          session.snapshot.status != InviteLifecycleStatus.active ||
          !session.snapshot.expiresAt.isAfter(DateTime.now())) {
        return null;
      }
      final status = [
        session.serverStatus?.index ?? -1,
        session.pendingStatus?.index ?? -1,
      ];
      if (!status.contains(InviteParticipationStatus.started.index) ||
          status.any(
            (value) =>
                value >= InviteParticipationStatus.completedPrivate.index,
          )) {
        return null;
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> start({
    required ActiveInviteSessions sessions,
    required Future<void> Function(InviteSession) schedule,
    required Future<void> Function() cancel,
    Stream<void>? audienceChanges,
  }) async {
    if (_subscription != null || _disposed) return;
    void observe(InviteSession session) {
      _tail = _tail
          .then((_) async {
            if (_disposed) return;
            final id = session.localSessionId;
            if (id == null) return;
            if (sessions.forLocalSessionId(id) == null) {
              if (_scheduledId == id) {
                _expiry?.cancel();
                _scheduledId = null;
                await cancel();
              }
              return;
            }
            if (!isAvailable() || !reminderEnabled() || !await isAdult()) {
              _scheduledId = null;
              _expiry?.cancel();
              await cancel();
              return;
            }
            await schedule(session);
            _scheduledId = id;
            _expiry?.cancel();
            final remaining = session.snapshot.expiresAt.difference(
              DateTime.now(),
            );
            if (remaining > Duration.zero) {
              _expiry = Timer(remaining, () {
                _tail = _tail
                    .then((_) async {
                      if (_scheduledId == id && !_disposed) {
                        _scheduledId = null;
                        await cancel();
                      }
                    })
                    .catchError((_) {});
              });
            }
          })
          .catchError((_) {});
    }

    _subscription = sessions.changes.listen(observe);
    _refreshImpl = () async {
      try {
        final stored = await store.eligibleStartedSessions();
        final active = stored
            .where(
              (s) => sessions.forLocalSessionId(s.localSessionId ?? '') != null,
            )
            .toList();
        if (active.isNotEmpty) {
          observe(active.last);
        } else {
          _tail = _tail
              .then((_) async {
                if (_disposed) return;
                _scheduledId = null;
                _expiry?.cancel();
                await cancel();
              })
              .catchError((_) {});
        }
      } catch (_) {
        await cancel();
      }
      await _tail;
    };
    _audienceSubscription = audienceChanges?.listen(
      (_) => unawaited(refresh()),
    );
    await refresh();
  }

  /// Rechecks availability, audience, permission and locale on app resume.
  Future<void> refresh() async {
    final refresh = _refreshImpl;
    try {
      if (refresh != null) await refresh();
    } catch (_) {
      TaliaLogger.w('Invitation reminder refresh unavailable');
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _expiry?.cancel();
    await _subscription?.cancel();
    await _audienceSubscription?.cancel();
    await _tail;
  }
}
