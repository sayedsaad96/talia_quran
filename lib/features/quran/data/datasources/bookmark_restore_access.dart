part of 'bookmark_service.dart';

/// Bookmark storage access held for the whole duration of a restore.
///
/// It runs inside the owner's operation queue, so toggles, pulls and pushes of
/// the same owner wait until the restore finishes instead of interleaving
/// between its snapshot and its writes. The methods below never re-enter that
/// queue.
class BookmarkRestoreAccess {
  BookmarkRestoreAccess._(this._service, this._ownerId);

  final BookmarkService _service;
  final String _ownerId;

  /// Every stored record, tombstones included, as a JSON list. Throws
  /// [PortableReadingDataException] when storage is unreadable, so a restore is
  /// refused rather than started without a rollback point.
  Future<String> capture() async {
    final records = await _readAll();
    return jsonEncode([for (final record in records) record.toJson()]);
  }

  /// Replaces the stored records with [snapshot]. Idempotent.
  Future<void> restoreSnapshot(String snapshot) async {
    final decoded = jsonDecode(snapshot) as List<dynamic>;
    final records = [
      for (final entry in decoded)
        BookmarkEntry.fromJson(entry as Map<String, dynamic>),
    ];
    await _service._writeRecords(_ownerId, records);
    _service._notifyChanged();
  }

  /// Adds the entries whose reference has no record yet, as new unsynced
  /// mutations. An existing record, live or logically deleted, is never
  /// changed or revived. Returns how many entries were added.
  Future<int> addMissing(List<BookmarkEntry> entries) async {
    final records = await _readAll();
    final existing = {for (final record in records) record.key};
    var added = 0;
    for (final entry in entries) {
      if (!existing.add(entry.key)) continue;
      records.add(
        entry.copyWith(
          revision: _service._nextRevision(0),
          isDeleted: false,
          isSynced: false,
        ),
      );
      added++;
    }
    if (added == 0) return 0;
    await _service._writeRecords(_ownerId, records);
    await _service._finishLegacyMigration(_ownerId);
    await _service._schedulePush(_ownerId);
    _service._notifyChanged();
    return added;
  }

  Future<List<BookmarkEntry>> _readAll() async {
    try {
      await _service._loadRecords(_ownerId, refresh: true);
      return await _service._recordsForMutation(_ownerId);
    } on StateError {
      throw const PortableReadingDataException(
        'Bookmark storage is unreadable',
      );
    }
  }
}

/// Runs [body] with exclusive bookmark access for [ownerId].
Future<T> _runBookmarkRestore<T>(
  BookmarkService service,
  String ownerId,
  Future<T> Function(BookmarkRestoreAccess access) body,
) async {
  if (!service._isActiveOwner(ownerId)) {
    throw const PortableReadingDataException(
      'Bookmark restore owner is not the active account',
    );
  }
  return await service._serialize(
    ownerId,
    () => body(BookmarkRestoreAccess._(service, ownerId)),
  );
}
