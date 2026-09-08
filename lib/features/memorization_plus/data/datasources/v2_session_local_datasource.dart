// Thin Isar wrapper for audience- and account-scoped V2 session persistence.

import 'package:isar/isar.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/kids_session_policy.dart';
import '../models/isar_v2_session.dart';

class V2SessionLocalDatasource {
  const V2SessionLocalDatasource(
    this._isar, {
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
  }) : _owner = owner;

  final Isar _isar;
  final RecordOwnerProvider _owner;
  static int _sessionNonce = 0;

  String get currentOwnerId => _owner.currentOwnerId;

  /// Returns the most recently saved session for the active owner/audience.
  /// Legacy rows are deliberately excluded from kids so adult state can never
  /// surface as a child mission.
  Future<IsarV2Session?> getLatestSession({
    MemorizationAudience audience = MemorizationAudience.adult,
  }) async {
    final sessions = await _isar.isarV2Sessions.where().findAll();
    final owned =
        sessions
            .where(
              (session) =>
                  session.ownerId == currentOwnerId &&
                  session.audienceIndex == audience.index,
            )
            .toList()
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    if (owned.isEmpty) return null;
    return _backfillSessionIdIfNeeded(owned.first);
  }

  Future<IsarV2Session?> getSession(
    int surahId, {
    MemorizationAudience audience = MemorizationAudience.adult,
  }) async {
    final key = IsarV2Session.keyFor(
      ownerId: currentOwnerId,
      audience: audience,
      surahId: surahId,
    );
    final sessions = await _isar.isarV2Sessions.where().findAll();
    for (final session in sessions) {
      if (session.sessionKey == key) return _backfillSessionIdIfNeeded(session);
    }

    // Never assign an ownerless legacy session to whichever account happens
    // to sign in next. There is no evidence that it belongs to that account;
    // treating it as resumable could expose another learner's memorization
    // state. A later guided verification migration can offer recovery without
    // silently claiming the state.
    return null;
  }

  Future<void> saveSession(IsarV2Session session) async {
    await _isar.writeTxn(() async {
      // `create()` does not know the old opaque id. Preserve it under the
      // stable sessionKey so every checkpoint in one session shares evidence.
      final existing = await _isar.isarV2Sessions
          .filter()
          .sessionKeyEqualTo(session.sessionKey)
          .findFirst();
      if (existing != null) {
        session.id = existing.id;
        session.sessionId ??= existing.sessionId;
      }
      session.sessionId ??= _newSessionId();
      await _isar.isarV2Sessions.put(session);
    });
  }

  Future<IsarV2Session> _backfillSessionIdIfNeeded(
    IsarV2Session session,
  ) async {
    if (session.sessionId != null && session.sessionId!.isNotEmpty) {
      return session;
    }
    session.sessionId = _newSessionId();
    await saveSession(session);
    return session;
  }

  static String _newSessionId() {
    final nonce = ++_sessionNonce;
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
    return 'v2-$micros-${nonce.toRadixString(36)}';
  }

  Future<void> clearSession(
    int surahId, {
    MemorizationAudience audience = MemorizationAudience.adult,
  }) async {
    final session = await getSession(surahId, audience: audience);
    if (session == null) return;
    await _isar.writeTxn(() async {
      await _isar.isarV2Sessions.delete(session.id);
    });
  }
}
