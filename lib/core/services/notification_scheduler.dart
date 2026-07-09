import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

import 'notification_service.dart';

class NotificationScheduler {
  final TaliaNotificationService _service;

  NotificationScheduler(this._service);

  Future<void> refreshNotifications(AppLocalizations l10n) async {
    final prefs = await SharedPreferences.getInstance();

    // First, sync timezone
    await _service.configureLocalTimezone();

    final reviewEnabled =
        prefs.getBool(TaliaNotificationService.dailyReviewPreferenceKey) ??
        true;
    final streakEnabled =
        prefs.getBool(TaliaNotificationService.streakAlertPreferenceKey) ??
        true;
    final morningAzkarEnabled =
        prefs.getBool(TaliaNotificationService.morningAzkarPreferenceKey) ??
        true;
    final eveningAzkarEnabled =
        prefs.getBool(TaliaNotificationService.eveningAzkarPreferenceKey) ??
        true;
    final dailyDuaEnabled =
        prefs.getBool(TaliaNotificationService.dailyDuaPreferenceKey) ?? true;
    final kidsReviewEnabled =
        prefs.getBool(TaliaNotificationService.kidsReminderPreferenceKey) ??
        false;

    if (reviewEnabled) {
      final hour =
          prefs.getInt(
            '${TaliaNotificationService.dailyReviewPreferenceKey}_hour',
          ) ??
          20;
      final minute =
          prefs.getInt(
            '${TaliaNotificationService.dailyReviewPreferenceKey}_minute',
          ) ??
          0;
      // Note: we can pass pending review count if we had it, but default is 0
      final body = l10n.notificationDailyReviewBody;
      await _service.scheduleDailyReviewReminder(
        title: l10n.notificationDailyReviewTitle,
        body: body,
        hour: hour,
        minute: minute,
      );
    } else {
      await _service.cancelDailyReviewReminder();
      if (streakEnabled) {
        final hour =
            prefs.getInt(
              '${TaliaNotificationService.streakAlertPreferenceKey}_hour',
            ) ??
            22;
        final minute =
            prefs.getInt(
              '${TaliaNotificationService.streakAlertPreferenceKey}_minute',
            ) ??
            0;
        await _service.scheduleStreakProtectionAlert(
          title: l10n.notificationStreakAlertTitle(1),
          body: l10n.notificationStreakAlertBody,
          currentStreak: 1,
          hour: hour,
          minute: minute,
        );
      }
    }

    await _service.scheduleDailyAyahReminder(
      title: l10n.notificationDailyAyahTitle,
      body: l10n.notificationDailyAyahBody,
    );

    if (morningAzkarEnabled) {
      final hour =
          prefs.getInt(
            '${TaliaNotificationService.morningAzkarPreferenceKey}_hour',
          ) ??
          6;
      final minute =
          prefs.getInt(
            '${TaliaNotificationService.morningAzkarPreferenceKey}_minute',
          ) ??
          0;
      await _service.scheduleMorningAzkarReminder(
        title: l10n.notificationMorningAzkarTitle,
        body: l10n.notificationMorningAzkarBody,
        hour: hour,
        minute: minute,
      );
    } else {
      await _service.cancelMorningAzkarReminder();
    }

    if (eveningAzkarEnabled) {
      final hour =
          prefs.getInt(
            '${TaliaNotificationService.eveningAzkarPreferenceKey}_hour',
          ) ??
          18;
      final minute =
          prefs.getInt(
            '${TaliaNotificationService.eveningAzkarPreferenceKey}_minute',
          ) ??
          0;
      await _service.scheduleEveningAzkarReminder(
        title: l10n.notificationEveningAzkarTitle,
        body: l10n.notificationEveningAzkarBody,
        hour: hour,
        minute: minute,
      );
    } else {
      await _service.cancelEveningAzkarReminder();
    }

    if (dailyDuaEnabled) {
      final hour =
          prefs.getInt(
            '${TaliaNotificationService.dailyDuaPreferenceKey}_hour',
          ) ??
          9;
      final minute =
          prefs.getInt(
            '${TaliaNotificationService.dailyDuaPreferenceKey}_minute',
          ) ??
          0;
      await _service.scheduleDailyDuaReminder(
        title: l10n.notificationDailyDuaTitle,
        hour: hour,
        minute: minute,
      );
    } else {
      await _service.cancelDailyDuaReminder();
    }

    if (kidsReviewEnabled) {
      final hour =
          prefs.getInt(
            '${TaliaNotificationService.kidsReminderPreferenceKey}_hour',
          ) ??
          18;
      final minute =
          prefs.getInt(
            '${TaliaNotificationService.kidsReminderPreferenceKey}_minute',
          ) ??
          30;
      await _service.scheduleKidsReviewReminder(
        title: l10n.notificationKidsReviewTitle,
        body: l10n.notificationKidsReviewBody,
        hour: hour,
        minute: minute,
      );
    } else {
      await _service.cancelKidsReviewReminder();
    }
  }
}
