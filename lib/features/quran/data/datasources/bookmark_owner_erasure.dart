part of 'bookmark_service.dart';

Future<void> _eraseBookmarksForOwner(BookmarkService service, String ownerId) async {
  final encrypted = service._encryptedAccountPreferences;
  await encrypted?.delete(ownerId, BookmarkService._encryptedStorageKey);
  await encrypted?.delete(ownerId, service._storageKeyFor(ownerId));
  for (final key in [
    service._storageKeyFor(ownerId),
    '${service._storageKeyFor(ownerId)}_migrated',
    BookmarkService._legacyStorageKey,
  ]) {
    if (!await service._prefs.remove(key)) {
      throw StateError('Unable to erase bookmark storage');
    }
  }
  await PendingBookmarkRecoveryMarker.clear(service._prefs, ownerId);
  service._evictErasedOwner(ownerId);
}
