import '../../features/quran/domain/entities/quran_entities.dart';

/// Picks the passage a review session covers (N4).
///
/// Reviewing one isolated ayah per session hides the most common hifz
/// failure — the transition between ayahs — and turns 15 due ayahs into 15
/// sessions. The passage starts at the requested ayah and extends over the
/// following ayahs that are also due, on the same Mushaf page, up to
/// [defaultMaxAyahs]. Each ayah is still recited and scheduled on its own.
abstract final class ReviewPassagePicker {
  static const defaultMaxAyahs = 10;

  static List<Ayah> pick({
    required List<Ayah> surahAyahs,
    required int startAyah,
    required Set<int> dueAyahNumbers,
    int maxAyahs = defaultMaxAyahs,
  }) {
    final startIndex = surahAyahs.indexWhere(
      (a) => a.numberInSurah == startAyah,
    );
    if (startIndex < 0) return const [];
    final start = surahAyahs[startIndex];
    final passage = [start];
    for (var i = startIndex + 1; i < surahAyahs.length; i++) {
      if (passage.length >= maxAyahs) break;
      final ayah = surahAyahs[i];
      if (!dueAyahNumbers.contains(ayah.numberInSurah)) break;
      if (start.page != null && ayah.page != null && ayah.page != start.page) {
        break;
      }
      passage.add(ayah);
    }
    return passage;
  }
}
