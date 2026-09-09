import '../../../../core/journey/unified_journey_action.dart';
import '../../../khatmah/domain/entities/khatmah_plan.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../entities/continue_recitation.dart';

/// Builds the "continue recitation" hero from the user's own reading history.
///
/// Progress numbers come only from confirmed read pages or an active khatmah
/// daily target. The ayah range on a mushaf page is a location label, never a
/// substitute for how far the user has actually read.
class ContinueRecitationMapper {
  const ContinueRecitationMapper();

  static const totalQuranPages = 604;

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
    if (activeKhatmah != null && activeKhatmah.status == KhatmahStatus.active) {
      return _fromKhatmah(
        isArabic: isArabic,
        plan: activeKhatmah,
        page: dailyWirdPageDetail,
        now: moment,
      );
    }

    final resumePage = _quranPageFrom(lastRestorableLocation);
    final hasOpenedMushaf = resumePage != null || confirmedReadPages > 0;
    if (!hasOpenedMushaf) return null;

    if (dailyWirdPageDetail != null && dailyWirdPageDetail.ayahs.isNotEmpty) {
      return _fromPage(
        isArabic: isArabic,
        page: dailyWirdPageDetail,
        route:
            heroAction?.route ??
            lastRestorableLocation ??
            '/quran/page/${dailyWirdPageDetail.pageNumber}',
        confirmedReadPages: confirmedReadPages,
      );
    }

    if (resumePage == null) return null;
    return ContinueRecitation(
      surahName: isArabic ? 'القرآن الكريم' : 'The Quran',
      current: confirmedReadPages.clamp(0, totalQuranPages),
      total: totalQuranPages,
      percent: confirmedReadPages / totalQuranPages,
      route: lastRestorableLocation!,
      unit: ContinueRecitationUnit.pages,
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

  ContinueRecitation _fromPage({
    required bool isArabic,
    required QuranPageDetail page,
    required String route,
    required int confirmedReadPages,
  }) {
    final surah = page.surahs.isNotEmpty ? page.surahs.first : null;
    final ayahs = surah == null
        ? page.ayahs
        : page.ayahs.where((ayah) => ayah.surahId == surah.id).toList();
    final usable = ayahs.isNotEmpty ? ayahs : page.ayahs;
    final current = confirmedReadPages.clamp(0, totalQuranPages);
    return ContinueRecitation(
      surahName: surah == null
          ? (isArabic ? 'القرآن الكريم' : 'The Quran')
          : (isArabic ? surah.nameAr : surah.nameEn),
      surahId: surah?.id,
      startAyah: usable.isEmpty ? null : usable.first.numberInSurah,
      endAyah: usable.isEmpty ? null : usable.last.numberInSurah,
      current: current,
      total: totalQuranPages,
      percent: current / totalQuranPages,
      route: route,
      unit: ContinueRecitationUnit.pages,
      versePreview: usable.isEmpty ? null : usable.first.text,
    );
  }

  int? _quranPageFrom(String? location) {
    if (location == null || location.isEmpty) return null;
    final uri = Uri.tryParse(location);
    if (uri == null || uri.pathSegments.length < 3) return null;
    if (uri.pathSegments[0] != 'quran' || uri.pathSegments[1] != 'page') {
      return null;
    }
    final page = int.tryParse(uri.pathSegments[2]);
    if (page == null || page < 1 || page > totalQuranPages) return null;
    return page;
  }
}
