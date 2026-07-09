import '../../quran/domain/entities/quran_entities.dart';
import 'entities/hifz_entities.dart';

List<Surah> sortSurahsForHifzPath({
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

Set<int> buildUnlockedSurahIds({
  required List<Surah> orderedSurahs,
  required Map<int, SurahHifzProgress> progressMap,
}) {
  final unlockedSurahIds = <int>{};
  var allPreviousSurahsComplete = true;

  for (var i = 0; i < orderedSurahs.length; i++) {
    final surah = orderedSurahs[i];
    if (i == 0 || allPreviousSurahsComplete) {
      unlockedSurahIds.add(surah.id);
    }

    final isCurrentSurahComplete = progressMap[surah.id]?.isComplete ?? false;
    allPreviousSurahsComplete =
        allPreviousSurahsComplete && isCurrentSurahComplete;
  }

  return unlockedSurahIds;
}
