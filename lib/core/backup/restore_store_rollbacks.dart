import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/quran/data/datasources/bookmark_service.dart';

import 'portable_reading_backup_adapter.dart';
import 'restore_isar_snapshot.dart';
import 'restore_preferences_snapshot.dart';
import 'restore_recovery_journal.dart';

/// Names of the journal parts a restore can snapshot.
abstract final class RestorePart {
  static const isar = 'isar';
  static const prefs = 'prefs';
  static const bookmarks = 'bookmarks';
}

/// The per-store rollbacks shared by a failing restore and by startup
/// recovery, so both paths put data back through the same code.
class RestoreStoreRollbacks {
  const RestoreStoreRollbacks(
    this._isar,
    this._prefs,
    this._reading, {
    this.heldBookmarks,
  });

  final Isar _isar;
  final SharedPreferences _prefs;
  final PortableReadingBackupAdapter? _reading;

  /// Bookmark access already held by the restore that is rolling back. Its
  /// queue is occupied, so the rollback must use it instead of re-entering.
  final BookmarkRestoreAccess? heldBookmarks;

  Map<String, RestoreRollback> get registry => {
    RestorePart.isar: (ownerId, snapshot) =>
        RestoreIsarSnapshot(_isar).rollback(ownerId, snapshot),
    RestorePart.prefs: (ownerId, snapshot) =>
        RestorePreferencesSnapshot(_prefs).rollback(snapshot),
    if (heldBookmarks case final held?)
      RestorePart.bookmarks: (ownerId, snapshot) =>
          held.restoreSnapshot(snapshot)
    else if (_reading case final reading?)
      RestorePart.bookmarks: reading.rollbackBookmarks,
  };
}
