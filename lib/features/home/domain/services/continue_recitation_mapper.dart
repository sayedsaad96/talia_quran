import '../../../../core/journey/unified_journey_action.dart';
import '../../../khatmah/domain/entities/khatmah_plan.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../entities/continue_recitation.dart';

/// Builds the "continue recitation" hero strictly from an active khatmah.
///
/// Random reading or memorization never activates the recitation card: when
/// there is no `KhatmahStatus.active` plan the mapper returns null and the
/// home screen shows the start-khatmah invitation instead
/// (spec 2026-09-12, section 3.1).
class ContinueRecitationMapper {
  const ContinueRecitationMapper();

  static const totalQuranPages = 604;

  /// [heroAction], [lastRestorableLocation] and [confirmedReadPages] are
  /// retained for source compatibility with existing call sites; they no
  /// longer influence the result.
  ContinueRecitation? map({
    required bool isArabic,
    UnifiedJourneyAction? heroAction,
    String? lastRestorableLocation,
    QuranPageDetail? dailyWirdPageDetail,
    KhatmahPlan? activeKhatmah,
    DateTime? now,
    int confirmedReadPages = 0,
  }) {
    final moment = now ?? DateTime.now();
    if (activeKhatmah == null ||
        activeKhatmah.status != KhatmahStatus.active) {
      return null;
    }
    return _fromKhatmah(
      isArabic: isArabic,
      plan: activeKhatmah,
      page: dailyWirdPageDetail,
      now: moment,
    );
  }

  ContinueRecitation _fromKhatmah({
    required bool isArabic,
    required KhatmahPlan plan,
    required QuranPageDetail? page,
    required DateTime now,
  }) {
    final target = plan.dailyTargetFor(now);
    final total = (target.endPage - target.startPage + 1).clamp(1, 604);
    final current = plan.dailyCompletedPages(now).clamp(0, total);
    final surah = page?.surahs.isNotEmpty == true ? page!.surahs.first : null;
    final ayahs = page?.ayahs ?? const [];
    return ContinueRecitation(
      surahName: surah == null
          ? (isArabic ? 'ورد الختمة' : 'Khatmah portion')
          : (isArabic ? surah.nameAr : surah.nameEn),
      surahId: surah?.id,
      startAyah: ayahs.isEmpty ? null : ayahs.first.numberInSurah,
      endAyah: ayahs.isEmpty ? null : ayahs.last.numberInSurah,
      current: current,
      total: total,
      percent: current / total,
      route: '/quran/page/${plan.nextUnreadPage}?mode=khatmah',
      unit: ContinueRecitationUnit.pages,
      versePreview: ayahs.isEmpty ? null : ayahs.first.text,
    );
  }
}
