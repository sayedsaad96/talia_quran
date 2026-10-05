import 'package:flutter/widgets.dart';

import '../../features/memorization_plus/domain/entities/child_identity_policy.dart';
import '../../features/progress/domain/entities/progress_entities.dart';
import '../constants/surah_names.dart';
import '../services/achievement_service.dart';
import 'app_localizations.dart';
import 'cubit_message_codes.dart';

import '../utils/locale_number_formatter.dart';

extension TaliaLocalizationHelpers on BuildContext {
  AppLocalizations get _l10n => AppLocalizations.of(this);
  bool get _isArabic => Localizations.localeOf(this).languageCode == 'ar';

  String localizedSurahName(int surahId) {
    if (_isArabic) {
      return SurahNames.arabic[surahId] ??
          LocaleNumberFormatter.number(surahId, _l10n.localeName);
    }
    return SurahNames.english[surahId] ??
        LocaleNumberFormatter.number(surahId, _l10n.localeName);
  }

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
    return LocaleNumberFormatter.number(juzNumber, _l10n.localeName);
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
      CertificateType.juz => l10n.certificateTitleJuz(
        LocaleNumberFormatter.number(award.juzNumber ?? 1, _l10n.localeName),
      ),
      CertificateType.surah => _localizedSurahCertificateTitle(award),
      CertificateType.halfQuran => l10n.certificateTitleHalfQuran,
      CertificateType.fullQuran => l10n.certificateTitleFullQuran,
      CertificateType.khatmahReading =>
        _isArabic
            ? 'شهادة إتمام ختمة تلاوة القرآن'
            : 'Quran Khatmah Certificate',
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

    // K15 — daily session-limit gate: '@kids/daily_limit|<count>'.
    if (message.startsWith(CubitMessageCodes.kidsDailySessionLimitPrefix)) {
      final count = int.tryParse(message.split('|').last);
      if (count != null) {
        return l10n.kidsGamifiedDailyLimitReached(count);
      }
    }

    return switch (message) {
      CubitMessageCodes.hifzAudioPlaybackFailed => l10n.hifzAudioPlaybackFailed,
      CubitMessageCodes.hifzReviewSaveFailed => l10n.hifzReviewSaveFailed,
      CubitMessageCodes.hifzMemorizationSaveFailed =>
        l10n.hifzMemorizationSaveFailed,
      CubitMessageCodes.v2SurahLoadFailed => l10n.v2SurahLoadFailed,
      CubitMessageCodes.v2NoAyahsInRange => l10n.v2NoAyahsInRange,
      CubitMessageCodes.kidsAudioPlaybackFailed => l10n.kidsAudioPlaybackFailed,
      CubitMessageCodes.kidsMicPermissionDenied => l10n.micPermissionError,
      CubitMessageCodes.kidsRecordingUnavailable =>
        l10n.kidsRecordingUnavailable,
      CubitMessageCodes.kidsRecordingNotCaptured =>
        l10n.kidsRecordingNotCaptured,
      CubitMessageCodes.kidsRecitationMismatch => l10n.kidsRecitationMismatch,
      CubitMessageCodes.kidsJourneyStageLocked => l10n.kidsGamifiedLockedStage,
      CubitMessageCodes.kidsAyahAlreadyCompleted =>
        l10n.kidsAyahAlreadyCompleted,
      CubitMessageCodes.guardianSignInRequired =>
        l10n.guardianErrorSignInRequired,
      CubitMessageCodes.guardianCloudUnavailable =>
        l10n.guardianErrorCloudUnavailable,
      CubitMessageCodes.guardianOnlyForChildren =>
        l10n.guardianErrorOnlyForChildren,
      CubitMessageCodes.guardianAlreadyLinked =>
        l10n.guardianErrorAlreadyLinked,
      CubitMessageCodes.guardianParentModeAdultsOnly =>
        l10n.guardianErrorParentModeAdultsOnly,
      CubitMessageCodes.guardianLinkCodeInvalid =>
        l10n.guardianErrorLinkCodeInvalid,
      CubitMessageCodes.guardianChildHasGuardian =>
        l10n.guardianErrorChildHasGuardian,
      CubitMessageCodes.guardianSameAccount => l10n.guardianErrorSameAccount,
      CubitMessageCodes.parentRewardTitleRequired =>
        l10n.parentRewardErrorTitleRequired,
      CubitMessageCodes.parentRewardLimitReached =>
        l10n.parentRewardErrorLimitReached,
      CubitMessageCodes.parentRewardUnavailable =>
        l10n.parentRewardErrorUnavailable,
      CubitMessageCodes.childNicknameInvalid => l10n.childErrorNicknameInvalid(
        LocaleNumberFormatter.format(
          (ChildIdentityPolicy.maxNicknameLength).toString(),
          l10n.localeName,
        ),
      ),
      CubitMessageCodes.childAgeInvalid => l10n.childErrorAgeInvalid(
        LocaleNumberFormatter.format(
          (ChildIdentityPolicy.minAge).toString(),
          l10n.localeName,
        ),
        LocaleNumberFormatter.format(
          (ChildIdentityPolicy.maxAge).toString(),
          l10n.localeName,
        ),
      ),
      CubitMessageCodes.guardianChildNotLinked =>
        l10n.guardianErrorChildNotLinked,
      CubitMessageCodes.pinRecoveryUnavailable => l10n.pinRecoveryUnavailable,
      CubitMessageCodes.guardianUnlinkFailed => l10n.guardianErrorUnlinkFailed,
      CubitMessageCodes.guardianUnlinkBeforePathChangeFailed =>
        l10n.guardianErrorUnlinkBeforePathChange,
      CubitMessageCodes.childIdentityUpdateUnavailable =>
        l10n.childErrorIdentityUpdateUnavailable,
      CubitMessageCodes.errorCache => l10n.errorCacheMessage,
      CubitMessageCodes.errorNetwork => l10n.errorNetworkMessage,
      CubitMessageCodes.errorServer => l10n.errorUnknownMessage,
      CubitMessageCodes.errorNotFound => l10n.errorNotFoundMessage,
      CubitMessageCodes.errorParse => l10n.errorParseMessage,
      CubitMessageCodes.errorUnknown => l10n.errorUnknownMessage,
      CubitMessageCodes.kidsHomeMissionInvalidTitle =>
        l10n.kidsHomeMissionInvalidTitle,
      CubitMessageCodes.kidsPolicyConflict => l10n.kidsPolicyConflict,
      CubitMessageCodes.kidsHomeMissionUnavailable =>
        l10n.kidsHomeMissionUnavailable,
      CubitMessageCodes.accountDeletionFailed => l10n.accountDeletionFailed,
      CubitMessageCodes.accountDeletionCleanupFailed =>
        l10n.accountDeletionRemoteConfirmedCleanupFailed,
      CubitMessageCodes.accountDeletionSessionCleanupFailed =>
        l10n.accountDeletionSessionCleanupFailed,
      CubitMessageCodes.accountDeletionMarkerFailed =>
        l10n.accountDeletionProgressMarkerFailed,
      CubitMessageCodes.accountDeletionUnavailable =>
        l10n.accountDeletionUnavailable,
      _ => message,
    };
  }
}
