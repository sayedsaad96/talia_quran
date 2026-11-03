part of 'bookmark_service.dart';

/// Reads the durable bookmark state for [expectedOwnerId] inside the owner's
/// operation queue and reduces it to canonical references.
///
/// Fails (never returns a partial or empty list) when the owner is not the
/// active one, deletion is pending, storage is unreadable, or a stored
/// reference is not a valid Quran ayah.
Future<List<PortableBookmark>> _exportPortableBookmarks(
  BookmarkService service,
  String expectedOwnerId,
) async {
  if (!service._isActiveOwner(expectedOwnerId)) {
    throw const PortableReadingDataException(
      'Bookmark export owner is not the active account',
    );
  }
  return await service._serialize(expectedOwnerId, () async {
    if (!service._isActiveOwner(expectedOwnerId)) {
      throw const PortableReadingDataException(
        'Bookmark export owner changed during export',
      );
    }
    final List<BookmarkEntry> records;
    try {
      await service._loadRecords(expectedOwnerId, refresh: true);
      records = await service._recordsForMutation(expectedOwnerId);
    } on StateError {
      throw const PortableReadingDataException(
        'Bookmark storage is unreadable',
      );
    }
    if (!service._isActiveOwner(expectedOwnerId)) {
      throw const PortableReadingDataException(
        'Bookmark export owner changed during export',
      );
    }
    return records
        .where((bookmark) => !bookmark.isDeleted)
        .map(
          (bookmark) => PortableBookmark(
            surahId: bookmark.surahId,
            ayahNumber: bookmark.ayahNumber,
            savedAt: bookmark.savedAt,
          ),
        )
        .toList()
      ..sort((a, b) {
        final bySurah = a.surahId.compareTo(b.surahId);
        return bySurah != 0 ? bySurah : a.ayahNumber.compareTo(b.ayahNumber);
      });
  });
}
