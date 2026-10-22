import '../../quran/domain/entities/quran_entities.dart';
import '../../quran/domain/repositories/quran_repository.dart';
import '../domain/entities/prayer_review_selection.dart';
import '../../../core/constants/surah_names.dart';

final class PrayerReviewQuranReader {
  const PrayerReviewQuranReader(this._quran);
  final QuranRepository _quran;
  Future<List<Ayah>> readCanonical(Set<int> surahs) async {
    final result = <Ayah>[];
    final ordered = surahs.toList()..sort();
    for (final surah in ordered) {
      result.addAll(await _load(surah));
    }
    return List.unmodifiable(result);
  }

  Future<List<Ayah>> readPassage(PrayerReviewSelection selection) async {
    PrayerReviewValidation.checkSelection(selection);
    final ayahs = await _load(selection.surahId);
    return List.unmodifiable(
      ayahs.sublist(selection.startAyah - 1, selection.endAyah),
    );
  }

  Future<List<Ayah>> _load(int surahId) async {
    final count = SurahNames.ayahCount(surahId);
    if (count == 0) throw const FormatException('Invalid prayer review surah');
    final detail = (await _quran.getSurahDetail(
      surahId,
    )).fold((failure) => throw failure, (detail) => detail);
    if (detail.surah.id != surahId ||
        detail.ayahs.length != count ||
        detail.surah.ayahCount != count) {
      throw const FormatException('Incomplete canonical prayer review surah');
    }
    final ayahs = detail.ayahs.toList()
      ..sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah));
    var offset = 0;
    for (var surah = 1; surah < surahId; surah++) {
      offset += SurahNames.ayahCount(surah);
    }
    for (var i = 0; i < count; i++) {
      final ayah = ayahs[i];
      if (ayah.surahId != surahId ||
          ayah.numberInSurah != i + 1 ||
          ayah.number != offset + i + 1 ||
          ayah.text.isEmpty) {
        throw const FormatException(
          'Invalid canonical prayer review reference',
        );
      }
    }
    return List.unmodifiable(ayahs);
  }
}
