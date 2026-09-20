import 'dart:io';
import 'dart:ui' show Locale;

import 'package:shared_preferences/shared_preferences.dart';

import '../di/injection.dart';
import '../l10n/app_localizations.dart';
import '../utils/talia_logger.dart';
import '../../features/certificate/domain/entities/certificate_award.dart';
import 'notification_service.dart';

/// The milestone celebrations Phase C can fire. [streak] is defined for the
/// l10n surface but is currently NOT derivable from any certificate creation
/// path (no award or code path distinguishes a 30-day streak), so nothing
/// fires it yet — kept for future wiring without an l10n migration.
enum MilestoneNotificationType { juz, surah, khatmah, streak }

/// Pure milestone data resolved from an award; the CALLER resolves localized
/// strings, keeping this layer l10n-free and unit-testable.
typedef MilestoneNotificationData = ({
  MilestoneNotificationType type,
  int? juzNumber,
  String? surahName,
});

/// Maps a newly-earned [CertificateAward] onto a milestone celebration.
/// Returns null when no reliable milestone can be derived (e.g. halfQuran)
/// so the caller simply skips — no invented triggers.
MilestoneNotificationData? mapCertificateAwardToMilestone(
  CertificateAward award,
) {
  switch (award.type) {
    case CertificateType.juz:
      final juz =
          award.juzNumber ??
          int.tryParse(award.id.substring('cert_juz_'.length));
      if (juz == null || juz < 1 || juz > 30) return null;
      return (type: MilestoneNotificationType.juz, juzNumber: juz, surahName: null);
    case CertificateType.surah:
      final name = (award.surahNameEn ?? award.surahNameAr)?.trim();
      if (name == null || name.isEmpty) return null;
      return (
        type: MilestoneNotificationType.surah,
        juzNumber: null,
        surahName: name,
      );
    case CertificateType.khatmahReading:
    // Full-Quran memorization completion is a genuine khatmah completion.
    case CertificateType.fullQuran:
      return (
        type: MilestoneNotificationType.khatmah,
        juzNumber: null,
        surahName: null,
      );
    case CertificateType.halfQuran:
      // Half-way progress is celebrated by the in-app dialog, not a
      // milestone notification — no distinct milestone type exists for it.
      return null;
  }
}

/// Fire-and-forget entry point for the AchievementService certificate
/// creation path. All failures are contained: a notification problem must
/// never break certificate creation.
Future<void> fireCertificateMilestone(CertificateAward award) async {
  final data = mapCertificateAwardToMilestone(award);
  if (data == null) return;
  await fireMilestoneCelebration(data);
}

/// Khatmah archiving path entry point (the khatmah repository does not build
/// a CertificateAward; the archive entry itself is the completion event).
Future<void> fireKhatmahMilestone() => fireMilestoneCelebration((
  type: MilestoneNotificationType.khatmah,
  juzNumber: null,
  surahName: null,
));

/// Streak mercy ("يوم الرحمة") path: fired when a broken streak is mercifully
/// re-lit instead of reset — the gentle "الله رحيم، سلسلتك مستنياك" moment.
Future<void> fireStreakMercyCelebration() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    if (!getIt.isRegistered<TaliaNotificationService>()) return;
    final l10n = await _loadSavedLocaleL10n();
    await getIt<TaliaNotificationService>().showMilestoneCelebration(
      title: l10n.notificationStreakMercyTitle,
      body: l10n.notificationStreakMercyBody,
      payload: '/home',
    );
  } catch (error, stack) {
    TaliaLogger.w('Streak mercy celebration failed', error, stack);
  }
}

/// Resolves AppLocalizations through the saved app-locale preference (same
/// fallback pattern as NotificationSettingsCubit._reschedule — these fire
/// outside the widget tree).
Future<AppLocalizations> _loadSavedLocaleL10n() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString('app_locale') ?? 'ar';
  return lookupAppLocalizations(Locale(languageCode));
}

/// Resolves the milestone strings through the saved app-locale preference
/// (same fallback pattern as NotificationSettingsCubit._reschedule — these
/// fire outside the widget tree), then shows the immediate celebration.
Future<void> fireMilestoneCelebration(MilestoneNotificationData data) async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    if (!getIt.isRegistered<TaliaNotificationService>()) return;
    final l10n = await _loadSavedLocaleL10n();
    final (title, body) = switch (data.type) {
      MilestoneNotificationType.juz => (
        l10n.notificationMilestoneJuzTitle(data.juzNumber!),
        l10n.notificationMilestoneJuzBody(data.juzNumber!),
      ),
      MilestoneNotificationType.surah => (
        l10n.notificationMilestoneSurahTitle(data.surahName!),
        l10n.notificationMilestoneSurahBody(data.surahName!),
      ),
      MilestoneNotificationType.khatmah => (
        l10n.notificationMilestoneKhatmahTitle,
        l10n.notificationMilestoneKhatmahBody,
      ),
      MilestoneNotificationType.streak => (
        l10n.notificationMilestoneStreakTitle,
        l10n.notificationMilestoneStreakBody,
      ),
    };
    await getIt<TaliaNotificationService>()
        .showMilestoneCelebration(title: title, body: body);
  } catch (error, stack) {
    TaliaLogger.w('Milestone celebration notification failed', error, stack);
  }
}
