import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/invite_activity_target.dart';
import '../../domain/entities/invite_types.dart';
import '../../domain/entities/share_prompt_state.dart';

/// Installation data remains on this device across account changes.
final class ShareGoodLocalStore {
  ShareGoodLocalStore(this._secure, this._prefs);
  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;
  Future<void> _tail = Future.value();
  static const _participant = 'share_good_participant_key_v1';
  static const _index = 'share_good_session_index_v1';
  static const _pending = 'share_good_pending_incoming_v1';
  static const _sessionPrefix = 'share_good_session_v1_';
  static const _maxSessions = 20;
  static final _sessionKeyPattern = RegExp('^$_sessionPrefix[a-f0-9]{64}\$');
  static const identityPrefix = 'share_good_identity_pref_v1|';
  static const promptPrefix = 'share_good_prompt_v1|';
  static const impactPrefix = 'share_good_impact_seen_v1|';

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  String _randomId(int count) {
    final random = Random.secure();
    return base64Url
        .encode(List.generate(count, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  String _key(String token) =>
      '$_sessionPrefix${sha256.convert(utf8.encode(token))}';

  Future<String> participantKey() => _serialize(() async {
    final existing = await _secure.read(key: _participant);
    if (existing != null) return existing;
    final value = _randomId(32);
    await _secure.write(key: _participant, value: value);
    return value;
  });

  Future<List<String>> _readIndex() async {
    final raw = await _secure.read(key: _index);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List ||
          decoded.length > _maxSessions ||
          decoded.any(
            (key) => key is! String || !_sessionKeyPattern.hasMatch(key),
          ) ||
          decoded.toSet().length != decoded.length) {
        throw const FormatException();
      }
      return decoded.cast<String>();
    } catch (_) {
      throw const FormatException('Invalid session index');
    }
  }

  Future<InviteSession?> session(String token) => _serialize(() async {
    final key = _key(token);
    return (await _readIndex()).contains(key) ? _readSession(key) : null;
  });
  Future<InviteSession?> _readSession(String key) async {
    final raw = await _secure.read(key: key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final token = j['token'] as String;
      if (_key(token) != key) throw const FormatException();
      return InviteSession(
        token: token,
        localSessionId: j['localSessionId'] as String,
        snapshot: ResolvedInvite(
          token: token,
          target: InviteActivityTarget.fromJson(j['target']),
          moment: InviteMoment.values.byName(j['moment'] as String),
          mode: InviteMode.values.byName(j['mode'] as String),
          inviter: InviterIdentity(
            mode: InviteIdentityMode.values.byName(j['identityMode'] as String),
            visibleName: j['visibleName'] as String?,
          ),
          status: InviteLifecycleStatus.values.byName(j['status'] as String),
          expiresAt: DateTime.parse(j['expiresAt'] as String),
        ),
        serverStatus: _participation(j['serverStatus']),
        pendingStatus: _participation(j['pendingStatus']),
        awaitingConsent: j['awaitingConsent'] as bool,
      );
    } catch (_) {
      throw const FormatException('Invalid session');
    }
  }

  InviteParticipationStatus? _participation(Object? name) => name == null
      ? null
      : InviteParticipationStatus.values.byName(name as String);

  Future<void> saveSession(InviteSession session) => _serialize(() async {
    if (session.token != session.snapshot.token) {
      throw ArgumentError('Session token mismatch');
    }
    final key = _key(session.token);
    final old = await _readSession(key);
    final id = old?.localSessionId ?? _randomId(18);
    final s = session.snapshot;
    final data = {
      'token': session.token,
      'localSessionId': id,
      'target': s.target.toJson(),
      'moment': s.moment.name,
      'mode': s.mode.name,
      'identityMode': s.inviter.mode.name,
      'visibleName': s.inviter.visibleName,
      'status': s.status.name,
      'expiresAt': s.expiresAt.toIso8601String(),
      'serverStatus': session.serverStatus?.name,
      'pendingStatus': session.pendingStatus?.name,
      'awaitingConsent': session.awaitingConsent,
    };
    final index = await _readIndex()
      ..remove(key);
    index.add(key);
    await _secure.write(key: key, value: jsonEncode(data));
    final removed = <String>[];
    while (index.length > _maxSessions) {
      removed.add(index.removeAt(0));
    }
    await _secure.write(key: _index, value: jsonEncode(index));
    for (final entry in removed) {
      await _secure.delete(key: entry);
    }
  });

  Future<List<InviteSession>> sessionsWithPending() => _serialize(() async {
    final result = <InviteSession>[];
    for (final key in await _readIndex()) {
      final value = await _readSession(key);
      if (value != null && value.pendingStatus != null) result.add(value);
    }
    return result;
  });
  Future<InviteSession?> sessionByLocalId(String id) => _serialize(() async {
    for (final key in await _readIndex()) {
      final value = await _readSession(key);
      if (value?.localSessionId == id) return value;
    }
    return null;
  });
  Future<String?> pendingIncomingToken() =>
      _serialize(() => _secure.read(key: _pending));
  Future<void> setPendingIncomingToken(String token) =>
      _serialize(() => _secure.write(key: _pending, value: token));
  Future<bool> acknowledgePendingIncomingToken(String expected) =>
      _serialize(() async {
        if (await _secure.read(key: _pending) != expected) return false;
        await _secure.delete(key: _pending);
        return true;
      });

  InviteIdentityMode personalIdentityPreference(String ownerId) {
    final name = _prefs.getString('$identityPrefix$ownerId');
    return InviteIdentityMode.values.where((e) => e.name == name).firstOrNull ??
        InviteIdentityMode.firstName;
  }

  Future<bool> setPersonalIdentityPreference(
    String ownerId,
    InviteIdentityMode value,
  ) => _prefs.setString('$identityPrefix$ownerId', value.name);
  SharePromptState promptState(String ownerId) {
    final raw = _prefs.getString('$promptPrefix$ownerId');
    if (raw == null) return const SharePromptState();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return SharePromptState(
      lastShownAt: j['lastShownAt'] == null
          ? null
          : DateTime.parse(j['lastShownAt'] as String),
      dismissCount: j['dismissCount'] as int,
      shownCount: j['shownCount'] as int,
      invitesCreated: j['invitesCreated'] as int,
      educationSeen: j['educationSeen'] as bool,
    );
  }

  Future<bool> setPromptState(String ownerId, SharePromptState value) =>
      _prefs.setString(
        '$promptPrefix$ownerId',
        jsonEncode({
          'lastShownAt': value.lastShownAt?.toIso8601String(),
          'dismissCount': value.dismissCount,
          'shownCount': value.shownCount,
          'invitesCreated': value.invitesCreated,
          'educationSeen': value.educationSeen,
        }),
      );
  String? impactSeen(String ownerId) =>
      _prefs.getString('$impactPrefix$ownerId');
  Future<bool> setImpactSeen(String ownerId, String value) =>
      _prefs.setString('$impactPrefix$ownerId', value);
}
