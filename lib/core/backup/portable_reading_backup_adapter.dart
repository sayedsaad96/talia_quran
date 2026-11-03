import '../../features/quran/data/datasources/bookmark_service.dart';
import '../../features/quran/domain/entities/bookmark_entry.dart';
import '../services/app_session_service.dart';
import '../identity/account_data_barrier.dart';
import 'portable_reading_data.dart';

/// The v5 reading sections of a backup, read from their owning stores.
typedef PortableReadingSections = ({
  List<PortableBookmark> bookmarks,
  QuranReadingCheckpoint? checkpoint,
});

/// Builds the stored bookmark for a canonical reference, with the surah name
/// and ayah text taken from the bundled Quran corpus (never from a file).
/// Returns null when the reference cannot be resolved.
typedef BookmarkEntryResolver =
    Future<BookmarkEntry?> Function(PortableBookmark reference);

/// Bridges the bookmark and reader-position stores to the backup format.
///
/// Each store keeps ownership of its own data and concurrency rules; this
/// adapter only asks them for canonical references. Both reads fail rather
/// than yield an empty section when storage is unreadable.
class PortableReadingBackupAdapter {
  const PortableReadingBackupAdapter({
    required this._bookmarks,
    required this._session,
    required this._resolve,
  });

  final BookmarkService _bookmarks;
  final AppSessionService _session;
  final BookmarkEntryResolver _resolve;

  Iterable<String> checkpointKeysForOwner(String ownerId) =>
      _session.checkpointKeysForOwner(ownerId);

  Future<void> writeCheckpoint(
    String ownerId,
    int page,
    AccountDataLease lease,
  ) => _session.writeCheckpointUnderLease(ownerId, page, lease);

  /// Reads both sections for [ownerId]. Must not be called from inside an
  /// `AccountDataBarrier` work item: the checkpoint read queues on the same
  /// barrier. Callers capture a lease first and re-check it afterwards.
  Future<PortableReadingSections> export(String ownerId) async {
    final bookmarks = await _bookmarks.exportPortable(expectedOwnerId: ownerId);
    final checkpoint = await _session.exportQuranCheckpoint(
      expectedOwnerId: ownerId,
    );
    return (bookmarks: bookmarks, checkpoint: checkpoint);
  }

  /// Resolves every reference to a displayable bookmark before a restore
  /// starts. One unresolvable reference rejects the whole list.
  Future<List<BookmarkEntry>> resolve(List<PortableBookmark> references) async {
    final entries = <BookmarkEntry>[];
    for (final reference in references) {
      final entry = await _resolve(reference);
      if (entry == null ||
          entry.surahId != reference.surahId ||
          entry.ayahNumber != reference.ayahNumber) {
        throw const PortableReadingDataException(
          'Bookmark reference is not in the Quran corpus',
        );
      }
      entries.add(entry);
    }
    return entries;
  }

  /// Holds the owner's bookmark queue for a whole restore.
  Future<T> runBookmarkRestore<T>(
    String ownerId,
    Future<T> Function(BookmarkRestoreAccess access) body,
  ) => _bookmarks.runRestoreExclusive(expectedOwnerId: ownerId, body: body);

  /// Rollback used by the recovery journal, in and after the restoring
  /// process.
  Future<void> rollbackBookmarks(String ownerId, String snapshot) =>
      runBookmarkRestore(ownerId, (access) => access.restoreSnapshot(snapshot));
}
