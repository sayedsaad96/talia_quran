// lib/features/memorization_plus/data/datasources/v2_session_local_datasource.dart
//
// Thin Isar wrapper for V2 session persistence.
// Intentionally separate from MemorizationPlusLocalDatasource to avoid
// touching the 51KB monolith. Injected directly into V2SessionProgressAdapter.

import 'package:isar/isar.dart';

import '../models/isar_v2_session.dart';

/// Minimal datasource for reading/writing V2 session state from Isar.
final class V2SessionLocalDatasource {
  const V2SessionLocalDatasource(this._isar);

  final Isar _isar;

  /// Returns the saved session for [surahId], or null if none exists.
  Future<IsarV2Session?> getSession(int surahId) async {
    return _isar.isarV2Sessions
        .where()
        .surahIdEqualTo(surahId)
        .findFirst();
  }

  /// Saves (upserts) a session — unique index on surahId replaces previous.
  Future<void> saveSession(IsarV2Session session) async {
    await _isar.writeTxn(() async {
      await _isar.isarV2Sessions.put(session);
    });
  }

  /// Deletes the saved session for [surahId] after completion or abandon.
  Future<void> clearSession(int surahId) async {
    await _isar.writeTxn(() async {
      await _isar.isarV2Sessions
          .where()
          .surahIdEqualTo(surahId)
          .deleteAll();
    });
  }
}
