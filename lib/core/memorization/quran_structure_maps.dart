import '../../features/quran/data/datasources/quran_local_datasource.dart';
import '../../features/quran/data/models/ayah_model.dart';

/// Quran structure lookups shared by progress and certificate surfaces.
///
/// Built once from [QuranLocalDatasource] so surah counts and juz key maps
/// stay consistent across [ProgressRepositoryImpl] and [AchievementService].
class QuranStructureMaps {
  const QuranStructureMaps({
    required this.surahAyahCounts,
    required this.ayahKeysByJuz,
    this.ayahsByJuz = const {},
  });

  final Map<int, int> surahAyahCounts;
  final Map<int, Set<String>> ayahKeysByJuz;
  final Map<int, List<AyahModel>> ayahsByJuz;

  static Future<QuranStructureMaps> load(QuranLocalDatasource ds) async {
    final surahs = await ds.getSurahs();
    final surahAyahCounts = {
      for (final surah in surahs) surah.id: surah.ayahCount,
    };

    final ayahKeysByJuz = <int, Set<String>>{};
    var ayahsByJuz = <int, List<AyahModel>>{};
    try {
      ayahsByJuz = await ds.getAyahsGroupedByJuz();
      for (final entry in ayahsByJuz.entries) {
        ayahKeysByJuz[entry.key] = {
          for (final ayah in entry.value)
            '${ayah.surahId}_${ayah.numberInSurah}',
        };
      }
    } catch (_) {
      // Leave juz maps empty; downstream metrics treat memorizedJuz as 0.
    }

    return QuranStructureMaps(
      surahAyahCounts: surahAyahCounts,
      ayahKeysByJuz: ayahKeysByJuz,
      ayahsByJuz: ayahsByJuz,
    );
  }
}
