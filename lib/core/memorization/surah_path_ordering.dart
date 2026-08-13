import '../../features/quran/domain/entities/quran_entities.dart';

/// Orders surahs for adult practice-by-surah browsing.
///
/// `backward` lists from 114→1 (child/short-surah first historically);
/// any other path lists ascending by id.
List<Surah> sortSurahsForPracticePath({
  required List<Surah> surahs,
  required String? path,
}) {
  final sortedSurahs = List<Surah>.from(surahs);
  if (path == 'backward') {
    sortedSurahs.sort((a, b) => b.id.compareTo(a.id));
  } else {
    sortedSurahs.sort((a, b) => a.id.compareTo(b.id));
  }
  return sortedSurahs;
}
