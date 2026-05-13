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

List<HifzSegment> generateHifzSegments({
  required int surahId,
  required int totalAyahs,
}) {
  if (totalAyahs <= 0) return const [];

  if (totalAyahs <= 20) {
    return [
      HifzSegment(
        surahId: surahId,
        startAyah: 1,
        endAyah: totalAyahs,
        totalAyahs: totalAyahs,
      ),
    ];
  }

  final segments = <HifzSegment>[];
  for (var start = 1; start <= totalAyahs; start += 10) {
    final end = start + 9 > totalAyahs ? totalAyahs : start + 9;
    segments.add(
      HifzSegment(
        surahId: surahId,
        startAyah: start,
        endAyah: end,
        totalAyahs: totalAyahs,
      ),
    );
  }
  return segments;
}

HifzSegment? getSegmentEndingAt({
  required List<HifzSegment> segments,
  required int ayahNumber,
}) {
  for (final segment in segments) {
    if (segment.endAyah == ayahNumber) return segment;
  }
  return null;
}

HifzSegment? getSegmentContaining({
  required List<HifzSegment> segments,
  required int ayahNumber,
}) {
  for (final segment in segments) {
    if (ayahNumber >= segment.startAyah && ayahNumber <= segment.endAyah) {
      return segment;
    }
  }
  return null;
}

bool canUnlockNextAyah({
  required int currentAyah,
  required int totalAyahs,
  required List<HifzSegment> segments,
  required Set<String> passedSegmentKeys,
}) {
  if (currentAyah >= totalAyahs) return false;

  final currentSegment = getSegmentContaining(
    segments: segments,
    ayahNumber: currentAyah,
  );
  final nextSegment = getSegmentContaining(
    segments: segments,
    ayahNumber: currentAyah + 1,
  );

  if (currentSegment == null || nextSegment == null) return false;
  if (currentSegment == nextSegment) return true;

  return passedSegmentKeys.contains(currentSegment.key);
}

HifzSegment? getNextRequiredCheckpoint({
  required List<HifzSegment> segments,
  required Set<String> passedSegmentKeys,
  required Map<int, AyahProgress> progressMap,
}) {
  for (final segment in segments) {
    if (passedSegmentKeys.contains(segment.key)) continue;
    final endProgress = progressMap[segment.endAyah];
    if (endProgress == null) continue;
    if (endProgress.status == AyahStatus.review ||
        endProgress.status == AyahStatus.memorized ||
        endProgress.repetitions > 0) {
      return segment;
    }
  }
  return null;
}
