import '../../../../core/backup/portable_reading_data.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../domain/entities/bookmark_entry.dart';
import '../datasources/quran_local_datasource.dart';

/// Builds a stored bookmark from a canonical reference using the bundled
/// Quran corpus, the same source the reader uses when a bookmark is created.
///
/// Nothing but the reference and its time comes from a backup file; the surah
/// name and ayah text always come from here. Returns null when the corpus does
/// not contain the ayah or cannot be read.
class QuranCorpusBookmarkResolver {
  const QuranCorpusBookmarkResolver(this._datasource);

  final QuranLocalDatasource _datasource;

  Future<BookmarkEntry?> call(PortableBookmark reference) async {
    try {
      final ayahs = await _datasource.getAyahs(reference.surahId);
      for (final ayah in ayahs) {
        if (ayah.numberInSurah == reference.ayahNumber) {
          return BookmarkEntry(
            surahId: reference.surahId,
            surahName: SurahNames.nameAr(reference.surahId),
            ayahNumber: reference.ayahNumber,
            ayahText: ayah.text,
            savedAt: reference.savedAt,
          );
        }
      }
    } on Object catch (error, stack) {
      TaliaLogger.w('Bookmark reference could not be resolved', error, stack);
    }
    return null;
  }
}
