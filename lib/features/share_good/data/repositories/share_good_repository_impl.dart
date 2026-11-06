import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../../../../core/identity/account_data_barrier.dart';
import '../../share_good_config.dart';
import '../../domain/entities/good_impact.dart';
import '../../domain/entities/invite_activity_target.dart';
import '../../domain/entities/invite_types.dart';
import '../../domain/repositories/share_good_repository.dart';
import '../datasources/share_good_local_store.dart';
import '../datasources/share_good_remote_datasource.dart';

class ShareGoodRepositoryImpl implements ShareGoodRepository {
  ShareGoodRepositoryImpl({
    required this.remote,
    required this.local,
    required this.links,
    required this.timezone,
    bool Function()? isAvailable,
    Future<bool> Function()? isChild,
    DateTime Function()? clock,
    this.accountBarrier,
  }) : isAvailable = isAvailable ?? _available,
       isChild = isChild ?? _notChild,
       clock = clock ?? DateTime.now;
  final ShareGoodRemoteDatasource remote;
  final ShareGoodLocalStore local;
  final ShareGoodLinks links;
  final Future<String> Function() timezone;
  final bool Function() isAvailable;
  final Future<bool> Function() isChild;
  final DateTime Function() clock;
  final AccountDataBarrier? accountBarrier;
  static bool _available() => true;
  static Future<bool> _notChild() async => false;
  Future<void> _tail = Future.value();
  Future<T> _serial<T>(Future<T> Function() f) {
    final result = _tail.then((_) => f());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<Either<ShareGoodFailure, T>> _run<T>(Future<T> Function() f) async {
    try {
      if (!isAvailable()) {
        return const Left(ShareGoodFailure.featureUnavailable);
      }
      if (await isChild()) return const Left(ShareGoodFailure.notEligible);
      return Right(await f());
    } on ShareGoodRemoteException catch (e) {
      return Left(e.failure);
    } on FormatException {
      return const Left(ShareGoodFailure.featureUnavailable);
    } on TypeError {
      return const Left(ShareGoodFailure.featureUnavailable);
    } on PlatformException {
      return const Left(ShareGoodFailure.featureUnavailable);
    } on AccountDataUnavailableException {
      return const Left(ShareGoodFailure.authRequired);
    }
  }

  Future<Either<ShareGoodFailure, T>> _accountRun<T>(
    Future<T> Function(_ShareGoodCall call) action, {
    bool serialized = false,
  }) {
    if (!isAvailable()) {
      return Future.value(const Left(ShareGoodFailure.featureUnavailable));
    }
    final lease = accountBarrier?.snapshot;
    return _run(() {
      Future<T> execute() async {
        lease?.check();
        final result = await action((function, [params]) {
          lease?.check();
          return remote.call(function, params);
        });
        lease?.check();
        return result;
      }

      return serialized ? _serial(execute) : execute();
    });
  }

  Future<String> _timezone() async {
    try {
      return await timezone();
    } catch (_) {
      throw const ShareGoodRemoteException(ShareGoodFailure.featureUnavailable);
    }
  }

  Map<String, dynamic> _params(InviteContext c, String tz) => {
    'p_target': c.target.toJson(),
    'p_moment': c.moment == InviteMoment.beforeActivity ? 'before' : 'after',
    'p_mode': c.mode.name,
    'p_identity_mode': _wire(c.identity.mode.name),
    'p_visible_name': c.identity.visibleName,
    'p_timezone': tz,
  };
  @override
  Future<Either<ShareGoodFailure, CreatedInvite>> create(InviteContext ctx) =>
      _accountRun((call) async {
        final response = await call(
          'create_share_good_invite_v1',
          _params(ctx, await _timezone()),
        );
        return _created(response);
      });
  @override
  Future<Either<ShareGoodFailure, CreatedInvite>> continueChain(
    String parentToken,
    InviteContext ctx,
  ) => _accountRun((call) async {
    final response = await call('create_share_good_chain_invite_v1', {
      ..._params(ctx, await _timezone()),
      'p_parent_token': parentToken,
      'p_participant_key': await local.participantKey(),
    });
    final created = _created(response);
    // The bearer is returned only once, even if the local cache fails.
    try {
      final old = await local.session(parentToken);
      if (old != null) {
        await local.saveSession(
          _copy(
            old,
            server: InviteParticipationStatus.continuedAsNewInvite,
            pending: null,
          ),
        );
      }
    } catch (_) {
      // A later resolve recovers the server status.
    }
    return created;
  }, serialized: true);
  CreatedInvite _created(Map<String, dynamic> j) {
    final token = j['token'] as String;
    return CreatedInvite(
      token: token,
      shareUrl: links.build(token),
      context: _context(j),
      createdAt: DateTime.parse(j['created_at'] as String),
      expiresAt: DateTime.parse(j['expires_at'] as String),
    );
  }

  @override
  Future<Either<ShareGoodFailure, InviteSession>> resolve(String token) =>
      _serial(
        () => _run(() async {
          final old = await local.session(token);
          try {
            final j = await remote.call('resolve_share_good_invite_v1', {
              'p_token': token,
              'p_participant_key': await local.participantKey(),
            });
            final c = _context(j);
            final snapshot = ResolvedInvite(
              token: token,
              target: c.target,
              moment: c.moment,
              mode: c.mode,
              inviter: c.identity,
              status: _fromWire(
                InviteLifecycleStatus.values,
                j['status'] as String,
              ),
              expiresAt: DateTime.parse(j['expires_at'] as String),
            );
            final server = _max(
              old?.serverStatus,
              _status(j['participation_status']),
            );
            final pending = old?.pendingStatus;
            final session = InviteSession(
              token: token,
              snapshot: snapshot,
              serverStatus: server,
              pendingStatus:
                  pending != null &&
                      (server == null || pending.index > server.index)
                  ? pending
                  : null,
              awaitingConsent: old?.awaitingConsent ?? false,
              localSessionId: old?.localSessionId,
            );
            await local.saveSession(session);
            return (await local.session(token))!;
          } on ShareGoodRemoteException catch (e) {
            if (e.failure == ShareGoodFailure.network && old != null) {
              final snapshot = old.snapshot;
              if (snapshot.status == InviteLifecycleStatus.active &&
                  !snapshot.expiresAt.isAfter(clock())) {
                return InviteSession(
                  token: old.token,
                  snapshot: ResolvedInvite(
                    token: snapshot.token,
                    target: snapshot.target,
                    moment: snapshot.moment,
                    mode: snapshot.mode,
                    inviter: snapshot.inviter,
                    status: InviteLifecycleStatus.expired,
                    expiresAt: snapshot.expiresAt,
                  ),
                  serverStatus: old.serverStatus,
                  pendingStatus: old.pendingStatus,
                  awaitingConsent: old.awaitingConsent,
                  localSessionId: old.localSessionId,
                );
              }
              return old;
            }
            if (old != null &&
                (e.failure == ShareGoodFailure.expired ||
                    e.failure == ShareGoodFailure.invalidInvite)) {
              await local.saveSession(
                _withLifecycle(
                  old,
                  e.failure == ShareGoodFailure.expired
                      ? InviteLifecycleStatus.expired
                      : InviteLifecycleStatus.revoked,
                ),
              );
            }
            rethrow;
          }
        }),
      );
  @override
  Future<Either<ShareGoodFailure, InviteSession>> advance(
    String token,
    InviteParticipationStatus status,
  ) => _serial(
    () => _run(() async {
      if (status.index > InviteParticipationStatus.completedPrivate.index) {
        throw const ShareGoodRemoteException(ShareGoodFailure.invalidInvite);
      }
      final old = await local.session(token);
      if (old == null) {
        throw const ShareGoodRemoteException(ShareGoodFailure.invalidInvite);
      }
      if (_expired(old)) {
        await local.saveSession(
          _withLifecycle(
            old,
            old.snapshot.status == InviteLifecycleStatus.revoked
                ? InviteLifecycleStatus.revoked
                : InviteLifecycleStatus.expired,
          ),
        );
        throw const ShareGoodRemoteException(ShareGoodFailure.expired);
      }
      final desired = _max(_max(old.serverStatus, old.pendingStatus), status)!;
      if (old.serverStatus != null &&
          desired.index <= old.serverStatus!.index) {
        return old;
      }
      final pending = _copy(old, pending: desired);
      await local.saveSession(pending);
      return _flush(pending);
    }),
  );
  Future<InviteSession> _flush(InviteSession session) async {
    try {
      final j = await remote.call('advance_share_good_participation_v1', {
        'p_token': session.token,
        'p_participant_key': await local.participantKey(),
        'p_status': _wire(session.pendingStatus!.name),
      });
      final acknowledged = _status(j['status']);
      if (acknowledged == null) throw const FormatException('Missing status');
      final server = _max(session.serverStatus, acknowledged)!;
      final updated = _copy(
        session,
        server: server,
        pending: server.index >= session.pendingStatus!.index
            ? null
            : session.pendingStatus,
      );
      await local.saveSession(updated);
      return (await local.session(session.token))!;
    } on ShareGoodRemoteException catch (e) {
      if (e.failure == ShareGoodFailure.network) {
        return (await local.session(session.token))!;
      }
      if (e.failure == ShareGoodFailure.expired ||
          e.failure == ShareGoodFailure.invalidInvite) {
        await local.saveSession(
          _withLifecycle(
            session,
            e.failure == ShareGoodFailure.expired
                ? InviteLifecycleStatus.expired
                : InviteLifecycleStatus.revoked,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> replayPending() => _serial(() async {
    if (!isAvailable() || await isChild()) return;
    for (final session in await local.sessionsWithPending()) {
      if (_expired(session)) {
        await local.saveSession(
          _withLifecycle(
            session,
            session.snapshot.status == InviteLifecycleStatus.revoked
                ? InviteLifecycleStatus.revoked
                : InviteLifecycleStatus.expired,
          ),
        );
        continue;
      }
      try {
        await _flush(session);
      } on ShareGoodRemoteException {
        continue;
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
  });
  bool _expired(InviteSession s) =>
      s.snapshot.status != InviteLifecycleStatus.active ||
      !s.snapshot.expiresAt.isAfter(clock());
  @override
  Future<Either<ShareGoodFailure, InviteSession>> disclose(
    String token,
    String visibleName,
  ) => _accountRun((call) async {
    final old = await local.session(token);
    if (old == null) {
      throw const ShareGoodRemoteException(ShareGoodFailure.invalidInvite);
    }
    final j = await call('disclose_share_good_completion_v1', {
      'p_token': token,
      'p_participant_key': await local.participantKey(),
      'p_visible_name': visibleName,
    });
    final acknowledged = _status(j['status']);
    if (acknowledged == null) throw const FormatException('Missing status');
    final server = _max(old.serverStatus, acknowledged)!;
    final next = _copy(
      old,
      server: server,
      pending:
          old.pendingStatus != null && old.pendingStatus!.index > server.index
          ? old.pendingStatus
          : null,
    );
    await local.saveSession(next);
    return (await local.session(token))!;
  }, serialized: true);
  @override
  Future<Either<ShareGoodFailure, GoodImpact>> impact() =>
      _accountRun((call) async {
        final j = await call('get_share_good_impact_v1');
        return GoodImpact(
          invites: (j['invites'] as List)
              .map(
                (v) => InviteImpactSummary(
                  target: InviteActivityTarget.fromJson(v['target']),
                  status: _fromWire(
                    InviteLifecycleStatus.values,
                    v['status'] as String,
                  ),
                  expiresAt: DateTime.parse(v['expires_at'] as String),
                  opens: v['opens'] as int,
                  starts: v['starts'] as int,
                  completions: v['completions'] as int,
                ),
              )
              .toList(),
          responses: j['responses'] as int,
          completions: j['completions'] as int,
          downstreamReach: j['downstream_reach'] as int,
          acknowledgements: (j['acknowledgements'] as List)
              .map(
                (v) => NamedAcknowledgement(
                  target: InviteActivityTarget.fromJson(v['target']),
                  visibleName: v['visible_name'] as String,
                  completedAt: DateTime.parse(v['completed_at'] as String),
                ),
              )
              .toList(),
          fetchedAt: DateTime.parse(j['fetched_at'] as String),
        );
      });
}

typedef _ShareGoodCall =
    Future<Map<String, dynamic>> Function(
      String function, [
      Map<String, dynamic>? params,
    ]);

String _wire(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
T _fromWire<T extends Enum>(List<T> values, String s) => values.firstWhere(
  (v) => _wire(v.name) == s,
  orElse: () => throw const FormatException('Unknown value'),
);
InviteParticipationStatus? _status(Object? s) =>
    s == null ? null : _fromWire(InviteParticipationStatus.values, s as String);
InviteParticipationStatus? _max(
  InviteParticipationStatus? a,
  InviteParticipationStatus? b,
) => a == null
    ? b
    : b == null || a.index >= b.index
    ? a
    : b;
InviteContext _context(Map<String, dynamic> j) {
  final i = Map<String, dynamic>.from(j['inviter'] as Map);
  return InviteContext(
    target: InviteActivityTarget.fromJson(j['target']),
    moment: switch (j['moment']) {
      'before' => InviteMoment.beforeActivity,
      'after' => InviteMoment.afterActivity,
      _ => throw const FormatException('Unknown moment'),
    },
    mode: _fromWire(InviteMode.values, j['mode'] as String),
    identity: InviterIdentity(
      mode: _fromWire(InviteIdentityMode.values, i['mode'] as String),
      visibleName: i['visible_name'] as String?,
    ),
  );
}

InviteSession _copy(
  InviteSession s, {
  InviteParticipationStatus? server,
  required InviteParticipationStatus? pending,
}) => InviteSession(
  token: s.token,
  snapshot: s.snapshot,
  serverStatus: server ?? s.serverStatus,
  pendingStatus: pending,
  awaitingConsent: s.awaitingConsent,
  localSessionId: s.localSessionId,
);

InviteSession _withLifecycle(InviteSession s, InviteLifecycleStatus status) {
  final v = s.snapshot;
  return InviteSession(
    token: s.token,
    snapshot: ResolvedInvite(
      token: v.token,
      target: v.target,
      moment: v.moment,
      mode: v.mode,
      inviter: v.inviter,
      status: status,
      expiresAt: v.expiresAt,
    ),
    serverStatus: s.serverStatus,
    pendingStatus: null,
    awaitingConsent: s.awaitingConsent,
    localSessionId: s.localSessionId,
  );
}
