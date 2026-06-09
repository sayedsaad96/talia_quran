import 'package:flutter/widgets.dart';

import '../../features/progress/domain/entities/progress_entities.dart';
import '../services/achievement_service.dart';
import 'app_localizations.dart';
import 'cubit_message_codes.dart';

extension TaliaLocalizationHelpers on BuildContext {
  AppLocalizations get _l10n => AppLocalizations.of(this);
  bool get _isArabic => Localizations.localeOf(this).languageCode == 'ar';

  String localizedJuzName(int juzNumber) {
    const arabicNames = [
      'الأول',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
      'السابع',
      'الثامن',
      'التاسع',
      'العاشر',
      'الحادي عشر',
      'الثاني عشر',
      'الثالث عشر',
      'الرابع عشر',
      'الخامس عشر',
      'السادس عشر',
      'السابع عشر',
      'الثامن عشر',
      'التاسع عشر',
      'العشرون',
      'الحادي والعشرون',
      'الثاني والعشرون',
      'الثالث والعشرون',
      'الرابع والعشرون',
      'الخامس والعشرون',
      'السادس والعشرون',
      'السابع والعشرون',
      'الثامن والعشرون',
      'التاسع والعشرون',
      'الثلاثون',
    ];

    if (_isArabic && juzNumber >= 1 && juzNumber <= arabicNames.length) {
      return arabicNames[juzNumber - 1];
    }
    return '$juzNumber';
  }

  String localizedAchievementTitle(Achievement achievement) {
    final l10n = _l10n;
    return switch (achievement.id) {
      'first_page' => l10n.achievementTitleFirstPage,
      'ten_pages' => l10n.achievementTitleTenPages,
      'fifty_pages' => l10n.achievementTitleFiftyPages,
      'juz_read' => l10n.achievementTitleJuzRead,
      'five_juz_read' => l10n.achievementTitleFiveJuzRead,
      'half_quran_read' => l10n.achievementTitleHalfQuranRead,
      'full_quran_read' => l10n.achievementTitleFullQuranRead,
      'first_ayah' => l10n.achievementTitleFirstAyah,
      'ten_ayahs' => l10n.achievementTitleTenAyahs,
      'fifty_ayahs' => l10n.achievementTitleFiftyAyahs,
      'hundred_ayahs' => l10n.achievementTitleHundredAyahs,
      'first_surah' => l10n.achievementTitleFirstSurah,
      'five_surahs' => l10n.achievementTitleFiveSurahs,
      'ten_surahs' => l10n.achievementTitleTenSurahs,
      'juz_amma' => l10n.achievementTitleJuzAmma,
      'one_juz_memorized' => l10n.achievementTitleOneJuzMemorized,
      'five_juz_memorized' => l10n.achievementTitleFiveJuzMemorized,
      'ten_juz_memorized' => l10n.achievementTitleTenJuzMemorized,
      'half_quran_memorized' => l10n.achievementTitleHalfQuranMemorized,
      'full_quran_memorized' => l10n.achievementTitleFullQuranMemorized,
      'three_day_streak' => l10n.achievementTitleThreeDayStreak,
      'week_streak' => l10n.achievementTitleWeekStreak,
      'two_week_streak' => l10n.achievementTitleTwoWeekStreak,
      'month_streak' => l10n.achievementTitleMonthStreak,
      'ninety_day_streak' => l10n.achievementTitleNinetyDayStreak,
      'year_streak' => l10n.achievementTitleYearStreak,
      _ => achievement.titleKey,
    };
  }

  String localizedAchievementDescription(Achievement achievement) {
    final l10n = _l10n;
    return switch (achievement.id) {
      'first_page' => l10n.achievementDescFirstPage,
      'ten_pages' => l10n.achievementDescTenPages,
      'fifty_pages' => l10n.achievementDescFiftyPages,
      'juz_read' => l10n.achievementDescJuzRead,
      'five_juz_read' => l10n.achievementDescFiveJuzRead,
      'half_quran_read' => l10n.achievementDescHalfQuranRead,
      'full_quran_read' => l10n.achievementDescFullQuranRead,
      'first_ayah' => l10n.achievementDescFirstAyah,
      'ten_ayahs' => l10n.achievementDescTenAyahs,
      'fifty_ayahs' => l10n.achievementDescFiftyAyahs,
      'hundred_ayahs' => l10n.achievementDescHundredAyahs,
      'first_surah' => l10n.achievementDescFirstSurah,
      'five_surahs' => l10n.achievementDescFiveSurahs,
      'ten_surahs' => l10n.achievementDescTenSurahs,
      'juz_amma' => l10n.achievementDescJuzAmma,
      'one_juz_memorized' => l10n.achievementDescOneJuzMemorized,
      'five_juz_memorized' => l10n.achievementDescFiveJuzMemorized,
      'ten_juz_memorized' => l10n.achievementDescTenJuzMemorized,
      'half_quran_memorized' => l10n.achievementDescHalfQuranMemorized,
      'full_quran_memorized' => l10n.achievementDescFullQuranMemorized,
      'three_day_streak' => l10n.achievementDescThreeDayStreak,
      'week_streak' => l10n.achievementDescWeekStreak,
      'two_week_streak' => l10n.achievementDescTwoWeekStreak,
      'month_streak' => l10n.achievementDescMonthStreak,
      'ninety_day_streak' => l10n.achievementDescNinetyDayStreak,
      'year_streak' => l10n.achievementDescYearStreak,
      _ => achievement.descriptionKey,
    };
  }

  String localizedCertificateTitle(CertificateAward award) {
    final l10n = _l10n;
    return switch (award.type) {
      CertificateType.juz => l10n.certificateTitleJuz(award.juzNumber ?? 1),
      CertificateType.surah => _localizedSurahCertificateTitle(award),
      CertificateType.halfQuran => l10n.certificateTitleHalfQuran,
      CertificateType.fullQuran => l10n.certificateTitleFullQuran,
    };
  }

  String _localizedSurahCertificateTitle(CertificateAward award) {
    final l10n = _l10n;
    final name = _isArabic ? award.surahNameAr : award.surahNameEn;
    if (name == null || name.trim().isEmpty) {
      return l10n.certificateTitleSurah;
    }
    return l10n.certificateTitleSurahNamed(name);
  }

  /// Resolves cubit/repository message codes to localized user-facing text.
  String localizedCubitMessage(String message) {
    final l10n = _l10n;

    if (message.startsWith(CubitMessageCodes.hifzSurahLockedPrefix)) {
      final parts = message.split('|');
      if (parts.length >= 3) {
        final surahName = _isArabic ? parts[1] : parts[2];
        return l10n.hifzSurahLockedMessage(surahName);
      }
    }

    if (message.startsWith(CubitMessageCodes.quizUnexpectedErrorPrefix)) {
      final error = message.substring(
        CubitMessageCodes.quizUnexpectedErrorPrefix.length,
      );
      return l10n.quizUnexpectedError(error);
    }

    return switch (message) {
      CubitMessageCodes.hifzAudioPlaybackFailed => l10n.hifzAudioPlaybackFailed,
      CubitMessageCodes.hifzReviewSaveFailed => l10n.hifzReviewSaveFailed,
      CubitMessageCodes.hifzMemorizationSaveFailed =>
        l10n.hifzMemorizationSaveFailed,
      CubitMessageCodes.kidsAudioPlaybackFailed => l10n.kidsAudioPlaybackFailed,
      CubitMessageCodes.quizSurahNotFound => l10n.quizSurahNotFound,
      CubitMessageCodes.quizAyahsOutsidePlan => l10n.quizAyahsOutsidePlan,
      CubitMessageCodes.quizNoMemorizedAyahs => l10n.quizNoMemorizedAyahs,
      _ => message,
    };
  }
}
