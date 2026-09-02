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
    return owned.isEmpty ? null : owned.first;
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
      if (session.sessionKey == key) return session;
    }

    // A pre-migration row had no owner/audience. Claim it only for the active
    // adult owner; a legacy row is never silently exposed to the child path.
    if (audience == MemorizationAudience.adult) {
      for (final session in sessions) {
        if (session.surahId == surahId && session.sessionKey == null) {
          session
            ..sessionKey = key
            ..ownerId = currentOwnerId
            ..audienceIndex = MemorizationAudience.adult.index;
          await saveSession(session);
          return session;
        }
      }
    }
    return null;
  }

  Future<void> saveSession(IsarV2Session session) async {
    await _isar.writeTxn(() async {
      await _isar.isarV2Sessions.put(session);
    });
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
