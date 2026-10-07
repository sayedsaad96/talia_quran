import '../constants/surah_names.dart';
import '../icons/talia_icons.dart';
import '../utils/locale_number_formatter.dart';
import '../router/app_router.dart';
import 'journey_presentation_data.dart';
import 'resume_session_presentation_input.dart';

class ResumeSessionPresentationMapper {
  const ResumeSessionPresentationMapper();

  JourneyPresentationData map(ResumeSessionPresentationInput input) {
    final uri = Uri.tryParse(input.route);

    if (uri == null) {
      return JourneyPresentationData(
        title: input.l10n.resumeWhereYouLeft,
        subtitle: input.l10n.savedPreviousActivity,
        icon: TaliaIcons.playCircleFilled,
        route: input.route,
      );
    }

    final metadata = input.metadata;
    final surahId = int.tryParse(
      metadata['surahId'] ?? uri.queryParameters['surahId'] ?? '',
    );
    final startAyah =
        int.tryParse(
          metadata['startAyah'] ?? uri.queryParameters['startAyah'] ?? '',
        ) ??
        int.tryParse(
          metadata['ayahNumber'] ?? uri.queryParameters['ayahNumber'] ?? '',
        );

    if (uri.path.startsWith('/quran/page/')) {
      final page = uri.pathSegments.length >= 3 ? uri.pathSegments[2] : null;
      return JourneyPresentationData(
        title: input.isArabic ? 'تابع قراءة القرآن' : 'Continue Quran Reading',
        subtitle: page == null
            ? input.l10n.lastSavedReading
            : input.isArabic
            ? 'الصفحة ${LocaleNumberFormatter.format(page, input.l10n.localeName)}'
            : 'Page $page',
        icon: TaliaIcons.mushaf,
        route: input.route,
      );
    }

    if (uri.path.startsWith('/quran/surah/')) {
      final id = uri.pathSegments.length >= 3
          ? int.tryParse(uri.pathSegments[2])
          : null;
      final surah = _surahLabel(input, id);
      return JourneyPresentationData(
        title: input.isArabic ? 'تابع $surah' : 'Continue $surah',
        subtitle: input.l10n.lastSavedReading,
        icon: TaliaIcons.mushaf,
        route: input.route,
      );
    }

    if (uri.path == AppRoutes.memorizationPlusKids) {
      return _kidsStageInfo(input, surahId, startAyah);
    }

    if (uri.path == AppRoutes.memorizationPlusKidsJourney) {
      final surah = _surahLabel(input, surahId);
      return JourneyPresentationData(
        title: input.isArabic ? 'تابع رحلة الطفل' : 'Continue Kids Journey',
        subtitle: surahId == null
            ? input.l10n.savedPreviousActivity
            : input.isArabic
            ? 'خريطة $surah'
            : '$surah map',
        icon: TaliaIcons.journey,
        route: input.route,
      );
    }

    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'memorization-plus' &&
        uri.pathSegments[1] == 'journey') {
      final id = int.tryParse(uri.pathSegments[2]);
      final surah = _surahLabel(input, id);
      return JourneyPresentationData(
        title: input.isArabic ? 'تابع رحلة الطفل' : 'Continue Kids Journey',
        subtitle: input.isArabic ? 'خريطة $surah' : '$surah map',
        icon: TaliaIcons.journey,
        route: input.route,
      );
    }

    return JourneyPresentationData(
      title: input.l10n.resumeWhereYouLeft,
      subtitle: input.l10n.savedPreviousActivity,
      icon: TaliaIcons.playCircleFilled,
      route: input.route,
    );
  }

  JourneyPresentationData _kidsStageInfo(
    ResumeSessionPresentationInput input,
    int? surahId,
    int? ayahNumber,
  ) {
    final stage = ayahNumber == null ? null : ((ayahNumber - 1) ~/ 5) + 1;
    final surah = _surahLabel(input, surahId);
    return JourneyPresentationData(
      title: stage == null
          ? (input.isArabic ? 'تابع مهمة الطفل' : 'Continue Kids Mission')
          : input.isArabic
          ? 'تابع المرحلة ${LocaleNumberFormatter.number(stage, input.l10n.localeName)}'
          : 'Continue Stage ${LocaleNumberFormatter.number(stage, input.l10n.localeName)}',
      subtitle: ayahNumber == null
          ? input.l10n.incompleteKidsSession
          : input.isArabic
          ? '$surah، الآية ${LocaleNumberFormatter.number(ayahNumber, input.l10n.localeName)}'
          : '$surah, ayah ${LocaleNumberFormatter.number(ayahNumber, input.l10n.localeName)}',
      icon: TaliaIcons.flag,
      route: input.route,
    );
  }

  String _surahLabel(ResumeSessionPresentationInput input, int? surahId) {
    if (surahId == null) return input.l10n.surah;
    if (input.isArabic) {
      return '${input.l10n.surah} ${SurahNames.nameAr(surahId)}';
    }
    return 'Surah ${SurahNames.nameEn(surahId)}';
  }
}
