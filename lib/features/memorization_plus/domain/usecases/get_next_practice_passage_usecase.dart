import '../../../../core/memorization/learning_launch_context.dart';
import '../../../../core/router/app_router.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

/// Keeps split-surah practice in its selected surah and passage size.
class GetNextPracticePassageUseCase {
  const GetNextPracticePassageUseCase(this._quranRepository);

  final QuranRepository _quranRepository;

  Future<({String route, int remaining})?> call({
    required int surahId,
    required int completedThroughAyah,
    required int passageSize,
  }) async {
    if (surahId < 1 ||
        surahId > 114 ||
        passageSize < 1 ||
        completedThroughAyah < 1) {
      return null;
    }
    final result = await _quranRepository.getSurahDetail(surahId);
    final detail = result.fold((_) => null, (value) => value);
    if (detail == null || detail.surah.id != surahId) return null;
    final total = detail.surah.ayahCount;
    final remaining = total - completedThroughAyah;
    if (remaining <= 0 || detail.ayahs.length != total) return null;
    final count = passageSize.clamp(1, remaining);
    final start = completedThroughAyah + 1;
    final numbers = detail.ayahs
        .where((ayah) => ayah.surahId == surahId)
        .map((ayah) => ayah.numberInSurah)
        .toSet();
    for (var number = start; number < start + count; number++) {
      if (!numbers.contains(number)) return null;
    }
    final launch = LearningLaunchContext(
      ayah: AyahReference(surahId: surahId, ayahNumber: start),
      intent: LearningIntent.memorize,
      origin: LearningOrigin.surahPractice,
    );
    return (
      route: Uri(
        path: AppRoutes.memorizationV2Session,
        queryParameters: {...launch.toRouteQuery(), 'blockSize': '$count'},
      ).toString(),
      remaining: remaining,
    );
  }
}
