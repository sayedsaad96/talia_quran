import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/services/notification_service.dart';
import 'notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit(
    this._prefs,
    this._notificationService, [
    this._scheduler,
  ]) : super(const NotificationSettingsState());

  final SharedPreferences _prefs;
  final TaliaNotificationService _notificationService;
  final NotificationScheduler? _scheduler;

  /// Loads all notification settings from persistent preferences and OS permission state.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true));

    final permissionGranted =
        await _notificationService.areNotificationsGranted();

    final dailyReview =
        _prefs.getBool(TaliaNotificationService.dailyReviewPreferenceKey) ??
        true;
    final streakAlert =
        _prefs.getBool(TaliaNotificationService.streakAlertPreferenceKey) ??
        true;
    final dailyAyah =
        _prefs.getBool(TaliaNotificationService.dailyAyahPreferenceKey) ?? true;
    final morningAzkar =
        _prefs.getBool(TaliaNotificationService.morningAzkarPreferenceKey) ??
        true;
    final eveningAzkar =
        _prefs.getBool(TaliaNotificationService.eveningAzkarPreferenceKey) ??
        true;
    final dailyDua =
        _prefs.getBool(TaliaNotificationService.dailyDuaPreferenceKey) ?? true;
    final kidsReminder =
        _prefs.getBool(TaliaNotificationService.kidsReminderPreferenceKey) ??
        false;
    final fridayKahf =
        _prefs.getBool(TaliaNotificationService.fridayKahfPreferenceKey) ?? true;
    final tahajjud =
        _prefs.getBool(TaliaNotificationService.tahajjudPreferenceKey) ?? false;
    final khatmahReminder =
        _prefs.getBool(TaliaNotificationService.khatmahReminderPreferenceKey) ??
        true;
    final prayerNotifications =
        _prefs.getBool(
          TaliaNotificationService.prayerNotificationsPreferenceKey,
        ) ??
        false;

    final prayerAthan =
        _prefs.getBool(TaliaNotificationService.prayerAthanKey) ?? false;
    final prayerFajr =
        _prefs.getBool(TaliaNotificationService.prayerFajrKey) ?? true;
    final prayerDhuhr =
        _prefs.getBool(TaliaNotificationService.prayerDhuhrKey) ?? true;
    final prayerAsr =
        _prefs.getBool(TaliaNotificationService.prayerAsrKey) ?? true;
    final prayerMaghrib =
        _prefs.getBool(TaliaNotificationService.prayerMaghribKey) ?? true;
    final prayerIsha =
        _prefs.getBool(TaliaNotificationService.prayerIshaKey) ?? true;
    final quietHoursEnabled =
        _prefs.getBool(TaliaNotificationService.quietHoursPreferenceKey) ??
        false;
    final quietHoursStart =
        _prefs.getInt(TaliaNotificationService.quietHoursStartKey) ?? 23;
    final quietHoursEnd =
        _prefs.getInt(TaliaNotificationService.quietHoursEndKey) ?? 4;
    final smartReminder =
        _prefs.getBool(TaliaNotificationService.smartReminderPreferenceKey) ??
        false;

    emit(
      state.copyWith(
        isLoading: false,
        hasSystemPermission: permissionGranted,
        dailyReview: dailyReview,
        streakAlert: streakAlert,
        dailyAyah: dailyAyah,
        morningAzkar: morningAzkar,
        eveningAzkar: eveningAzkar,
        dailyDua: dailyDua,
        kidsReminder: kidsReminder,
        fridayKahf: fridayKahf,
        tahajjud: tahajjud,
        khatmahReminder: khatmahReminder,
        prayerNotifications: prayerNotifications,
        prayerAthan: prayerAthan,
        prayerFajr: prayerFajr,
        prayerDhuhr: prayerDhuhr,
        prayerAsr: prayerAsr,
        prayerMaghrib: prayerMaghrib,
        prayerIsha: prayerIsha,
        quietHoursEnabled: quietHoursEnabled,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
        smartReminder: smartReminder,
        dailyReviewTime: _readTime(
          TaliaNotificationService.dailyReviewPreferenceKey,
          defaultHour: 20,
          defaultMinute: 0,
        ),
        streakAlertTime: _readTime(
          TaliaNotificationService.streakAlertPreferenceKey,
          defaultHour: 22,
          defaultMinute: 0,
        ),
        dailyAyahTime: _readTime(
          TaliaNotificationService.dailyAyahPreferenceKey,
          defaultHour: 7,
          defaultMinute: 0,
        ),
        morningAzkarTime: _readTime(
          TaliaNotificationService.morningAzkarPreferenceKey,
          defaultHour: 6,
          defaultMinute: 0,
        ),
        eveningAzkarTime: _readTime(
          TaliaNotificationService.eveningAzkarPreferenceKey,
          defaultHour: 18,
          defaultMinute: 0,
        ),
        dailyDuaTime: _readTime(
          TaliaNotificationService.dailyDuaPreferenceKey,
          defaultHour: 9,
          defaultMinute: 0,
        ),
        kidsReminderTime: _readTime(
          TaliaNotificationService.kidsReminderPreferenceKey,
          defaultHour: 18,
          defaultMinute: 30,
        ),
        fridayKahfTime: _readTime(
          TaliaNotificationService.fridayKahfPreferenceKey,
          defaultHour: 9,
          defaultMinute: 0,
        ),
        tahajjudTime: _readTime(
          TaliaNotificationService.tahajjudPreferenceKey,
          defaultHour: 3,
          defaultMinute: 30,
        ),
        khatmahReminderTime: _readTime(
          TaliaNotificationService.khatmahReminderPreferenceKey,
          defaultHour: 17,
          defaultMinute: 0,
        ),
      ),
    );
  }

  /// Re-checks system notification permission status from the OS.
  Future<void> checkPermission() async {
    final permissionGranted =
        await _notificationService.areNotificationsGranted();
    if (permissionGranted != state.hasSystemPermission) {
      emit(state.copyWith(hasSystemPermission: permissionGranted));
    }
  }

  /// Toggles a reminder by its preference key and persists to preferences.
  Future<void> toggleReminder(
    String preferenceKey,
    bool value, {
    AppLocalizations? l10n,
  }) async {
    await _prefs.setBool(preferenceKey, value);

    final updatedState = switch (preferenceKey) {
      TaliaNotificationService.dailyReviewPreferenceKey => state.copyWith(
        dailyReview: value,
      ),
      TaliaNotificationService.streakAlertPreferenceKey => state.copyWith(
        streakAlert: value,
      ),
      TaliaNotificationService.dailyAyahPreferenceKey => state.copyWith(
        dailyAyah: value,
      ),
      TaliaNotificationService.morningAzkarPreferenceKey => state.copyWith(
        morningAzkar: value,
      ),
      TaliaNotificationService.eveningAzkarPreferenceKey => state.copyWith(
        eveningAzkar: value,
      ),
      TaliaNotificationService.dailyDuaPreferenceKey => state.copyWith(
        dailyDua: value,
      ),
      TaliaNotificationService.kidsReminderPreferenceKey => state.copyWith(
        kidsReminder: value,
      ),
      TaliaNotificationService.fridayKahfPreferenceKey => state.copyWith(
        fridayKahf: value,
      ),
      TaliaNotificationService.tahajjudPreferenceKey => state.copyWith(
        tahajjud: value,
      ),
      TaliaNotificationService.khatmahReminderPreferenceKey => state.copyWith(
        khatmahReminder: value,
      ),
      TaliaNotificationService.prayerNotificationsPreferenceKey =>
        state.copyWith(prayerNotifications: value),
      TaliaNotificationService.prayerAthanKey => state.copyWith(
        prayerAthan: value,
      ),
      TaliaNotificationService.quietHoursPreferenceKey => state.copyWith(
        quietHoursEnabled: value,
      ),
      TaliaNotificationService.smartReminderPreferenceKey => state.copyWith(
        smartReminder: value,
      ),
      _ => state,
    };

    emit(updatedState);
    await _reschedule(l10n);
  }

  /// Updates the scheduled hour and minute for a reminder.
  Future<void> updateReminderTime(
    String preferenceKey,
    TimeOfDay time, {
    AppLocalizations? l10n,
  }) async {
    await _prefs.setInt('${preferenceKey}_hour', time.hour);
    await _prefs.setInt('${preferenceKey}_minute', time.minute);

    final updatedState = switch (preferenceKey) {
      TaliaNotificationService.dailyReviewPreferenceKey => state.copyWith(
        dailyReviewTime: time,
      ),
      TaliaNotificationService.streakAlertPreferenceKey => state.copyWith(
        streakAlertTime: time,
      ),
      TaliaNotificationService.dailyAyahPreferenceKey => state.copyWith(
        dailyAyahTime: time,
      ),
      TaliaNotificationService.morningAzkarPreferenceKey => state.copyWith(
        morningAzkarTime: time,
      ),
      TaliaNotificationService.eveningAzkarPreferenceKey => state.copyWith(
        eveningAzkarTime: time,
      ),
      TaliaNotificationService.dailyDuaPreferenceKey => state.copyWith(
        dailyDuaTime: time,
      ),
      TaliaNotificationService.kidsReminderPreferenceKey => state.copyWith(
        kidsReminderTime: time,
      ),
      TaliaNotificationService.fridayKahfPreferenceKey => state.copyWith(
        fridayKahfTime: time,
      ),
      TaliaNotificationService.tahajjudPreferenceKey => state.copyWith(
        tahajjudTime: time,
      ),
      TaliaNotificationService.khatmahReminderPreferenceKey => state.copyWith(
        khatmahReminderTime: time,
      ),
      _ => state,
    };

    emit(updatedState);
    await _reschedule(l10n);
  }

  /// Toggles an individual prayer notification in the prayer filter.
  Future<void> togglePrayer(
    String prayerKey,
    bool value, {
    AppLocalizations? l10n,
  }) async {
    await _prefs.setBool(prayerKey, value);

    final updatedState = switch (prayerKey) {
      TaliaNotificationService.prayerFajrKey => state.copyWith(
        prayerFajr: value,
      ),
      TaliaNotificationService.prayerDhuhrKey => state.copyWith(
        prayerDhuhr: value,
      ),
      TaliaNotificationService.prayerAsrKey => state.copyWith(
        prayerAsr: value,
      ),
      TaliaNotificationService.prayerMaghribKey => state.copyWith(
        prayerMaghrib: value,
      ),
      TaliaNotificationService.prayerIshaKey => state.copyWith(
        prayerIsha: value,
      ),
      _ => state,
    };

    emit(updatedState);
    await _reschedule(l10n);
  }

  /// Triggers an immediate interactive test notification.
  Future<bool> showTestNotification({
    required String title,
    required String body,
    String type = 'review',
  }) async {
    return _notificationService.showImmediateTestNotification(
      title: title,
      body: body,
      type: type,
    );
  }

  Future<bool> requestExactPrayerTimePermission() {
    return _notificationService.requestExactNotificationPermission();
  }

  Future<void> updateQuietHours({
    required int startHour,
    required int endHour,
    AppLocalizations? l10n,
  }) async {
    await _prefs.setInt(TaliaNotificationService.quietHoursStartKey, startHour);
    await _prefs.setInt(TaliaNotificationService.quietHoursEndKey, endHour);
    emit(
      state.copyWith(quietHoursStart: startHour, quietHoursEnd: endHour),
    );
    await _reschedule(l10n);
  }

  TimeOfDay _readTime(
    String key, {
    required int defaultHour,
    required int defaultMinute,
  }) {
    final hour = _prefs.getInt('${key}_hour') ?? defaultHour;
    final minute = _prefs.getInt('${key}_minute') ?? defaultMinute;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _reschedule(AppLocalizations? l10n) async {
    if (_scheduler == null) return;
    var effectiveL10n = l10n;
    if (effectiveL10n == null) {
      // Fall back to the saved locale preference so a reschedule triggered
      // without a BuildContext never silently skips (and never leaves stale
      // Arabic/English labels behind).
      final languageCode = _prefs.getString('app_locale') ?? 'ar';
      effectiveL10n = lookupAppLocalizations(Locale(languageCode));
    }
    try {
      await _scheduler.refreshNotifications(effectiveL10n, force: true);
    } catch (_) {}
  }
}
