import '../../features/quran/domain/entities/quran_entities.dart';
import '../memorization/learning_launch_context.dart';

/// Returns an initial reader highlight only when the requested ayah is on the
/// canonical page that was actually loaded.
({int surah, int ayah})? validatedInitialTargetForPage({
  required QuranPageDetail? detail,
  required AyahReference? target,
}) {
  if (detail == null || target == null) return null;
  if (target.surahId <= 0 || target.ayahNumber <= 0) return null;
  final matches = detail.ayahs.where(
    (ayah) =>
        ayah.surahId == target.surahId &&
        ayah.numberInSurah == target.ayahNumber &&
        ayah.page == detail.pageNumber,
  );
  return matches.length == 1
      ? (surah: target.surahId, ayah: target.ayahNumber)
      : null;
}
