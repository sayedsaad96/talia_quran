import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/prayer_sound.dart';
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

  /// Read-only access for widgets that need to read a preference that is
  /// not part of [NotificationSettingsState] (e.g. muezzin selection).
  SharedPreferences get prefs => _prefs;

  /// Loads all notification settings from persistent preferences and OS permission state.
  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));

    final permissionGranted = await _notificationService
        .areNotificationsGranted()
        .catchError((_) => false);
    if (isClosed) return;

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
        _prefs.getBool(TaliaNotificationService.fridayKahfPreferenceKey) ??
        true;
    final weeklyImpact =
        _prefs.getBool(TaliaNotificationService.weeklyImpactPreferenceKey) ??
        true;
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
    final rawMuezzin = _prefs.getString(
      TaliaNotificationService.prayerMuezzinKey,
    );
    final muezzinId =
        (rawMuezzin != null && MuezzinCatalog.isSupported(rawMuezzin))
        ? rawMuezzin
        : MuezzinCatalog.defaultId;
    final rawFajr =
        _prefs.getString(TaliaNotificationService.prayerMuezzinFajrKey) ?? '';
    final fajrMuezzinId =
        (rawFajr.isEmpty || MuezzinCatalog.isSupported(rawFajr)) ? rawFajr : '';

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
        weeklyImpact: weeklyImpact,
        tahajjud: tahajjud,
        khatmahReminder: khatmahReminder,
        prayerNotifications: prayerNotifications,
        prayerAthan: prayerAthan,
        prayerFajr: prayerFajr,
        prayerDhuhr: prayerDhuhr,
        prayerAsr: prayerAsr,
        prayerMaghrib: prayerMaghrib,
        prayerIsha: prayerIsha,
        muezzinId: muezzinId,
        fajrMuezzinId: fajrMuezzinId,
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
        weeklyImpactTime: _readTime(
          TaliaNotificationService.weeklyImpactPreferenceKey,
          defaultHour: 16,
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
    final permissionGranted = await _notificationService
        .areNotificationsGranted()
        .catchError((_) => false);
    if (!isClosed && permissionGranted != state.hasSystemPermission) {
      emit(state.copyWith(hasSystemPermission: permissionGranted));
    }
  }

  /// Toggles a reminder by its preference key and persists to preferences.
  Future<void> toggleReminder(
    String preferenceKey,
    bool value, {
    AppLocalizations? l10n,
  }) async {
    final saved = await _writeBool(preferenceKey, value);
    if (!saved) {
      _emitFeedback(state, NotificationSettingsFeedback.saveFailed);
      return;
    }
    final persistedValue = value;

    final updatedState = switch (preferenceKey) {
      TaliaNotificationService.dailyReviewPreferenceKey => state.copyWith(
        dailyReview: persistedValue,
      ),
      TaliaNotificationService.streakAlertPreferenceKey => state.copyWith(
        streakAlert: persistedValue,
      ),
      TaliaNotificationService.dailyAyahPreferenceKey => state.copyWith(
        dailyAyah: persistedValue,
      ),
      TaliaNotificationService.morningAzkarPreferenceKey => state.copyWith(
        morningAzkar: persistedValue,
      ),
      TaliaNotificationService.eveningAzkarPreferenceKey => state.copyWith(
        eveningAzkar: persistedValue,
      ),
      TaliaNotificationService.dailyDuaPreferenceKey => state.copyWith(
        dailyDua: persistedValue,
      ),
      TaliaNotificationService.kidsReminderPreferenceKey => state.copyWith(
        kidsReminder: persistedValue,
      ),
      TaliaNotificationService.fridayKahfPreferenceKey => state.copyWith(
        fridayKahf: persistedValue,
      ),
      TaliaNotificationService.weeklyImpactPreferenceKey => state.copyWith(
        weeklyImpact: persistedValue,
      ),
      TaliaNotificationService.tahajjudPreferenceKey => state.copyWith(
        tahajjud: persistedValue,
      ),
      TaliaNotificationService.khatmahReminderPreferenceKey => state.copyWith(
        khatmahReminder: persistedValue,
      ),
      TaliaNotificationService.prayerNotificationsPreferenceKey =>
        state.copyWith(prayerNotifications: persistedValue),
      TaliaNotificationService.prayerAthanKey => state.copyWith(
        prayerAthan: persistedValue,
      ),
      TaliaNotificationService.quietHoursPreferenceKey => state.copyWith(
        quietHoursEnabled: persistedValue,
      ),
      TaliaNotificationService.smartReminderPreferenceKey => state.copyWith(
        smartReminder: persistedValue,
      ),
      _ => state,
    };

    if (!isClosed) emit(updatedState);
    await _reschedule(l10n);
  }

  /// Updates the selected muezzin for the full adhan playback and
  /// reschedules prayer events so the new clip applies within seconds —
  /// without waiting for the next rolling-window refresh.
  Future<void> setMuezzin(String muezzinId, {AppLocalizations? l10n}) async {
    final saved = await _writeString(
      TaliaNotificationService.prayerMuezzinKey,
      muezzinId,
    );
    if (!saved) {
      _emitFeedback(state, NotificationSettingsFeedback.saveFailed);
      return;
    }
    if (!isClosed) emit(state.copyWith(muezzinId: muezzinId));
    await _reschedule(l10n);
  }

  /// Updates the Fajr-only muezzin override. An empty [fajrMuezzinId]
  /// clears the override (fajr uses the general muezzin).
  Future<void> setFajrMuezzin(
    String fajrMuezzinId, {
    AppLocalizations? l10n,
  }) async {
    final saved = await _writeString(
      TaliaNotificationService.prayerMuezzinFajrKey,
      fajrMuezzinId,
    );
    if (!saved) {
      _emitFeedback(state, NotificationSettingsFeedback.saveFailed);
      return;
    }
    if (!isClosed) emit(state.copyWith(fajrMuezzinId: fajrMuezzinId));
    await _reschedule(l10n);
  }

  /// Saves the general and Fajr choices and refreshes prayer notifications.
  Future<void> setMuezzinSelection({
    required String muezzinId,
    required String fajrMuezzinId,
    AppLocalizations? l10n,
  }) async {
    final previousMuezzin = _prefs.getString(
      TaliaNotificationService.prayerMuezzinKey,
    );
    final previousFajr = _prefs.getString(
      TaliaNotificationService.prayerMuezzinFajrKey,
    );
    final generalSaved = await _writeString(
      TaliaNotificationService.prayerMuezzinKey,
      muezzinId,
    );
    final fajrSaved = await _writeString(
      TaliaNotificationService.prayerMuezzinFajrKey,
      fajrMuezzinId,
    );
    final persistedMuezzin =
        _prefs.getString(TaliaNotificationService.prayerMuezzinKey) ??
        MuezzinCatalog.defaultId;
    final persistedFajr =
        _prefs.getString(TaliaNotificationService.prayerMuezzinFajrKey) ?? '';
    if (!isClosed) {
      emit(
        state.copyWith(
          muezzinId: persistedMuezzin,
          fajrMuezzinId: persistedFajr,
        ),
      );
    }
    if (persistedMuezzin != previousMuezzin || persistedFajr != previousFajr) {
      await _reschedule(l10n);
    }
    if (!generalSaved || !fajrSaved) {
      _emitFeedback(state, NotificationSettingsFeedback.saveFailed);
    }
  }

  /// Updates the scheduled hour and minute for a reminder.
  Future<void> updateReminderTime(
    String preferenceKey,
    TimeOfDay time, {
    AppLocalizations? l10n,
  }) async {
    final previousTime = switch (preferenceKey) {
      TaliaNotificationService.dailyReviewPreferenceKey =>
        state.dailyReviewTime,
      TaliaNotificationService.streakAlertPreferenceKey =>
        state.streakAlertTime,
      TaliaNotificationService.dailyAyahPreferenceKey => state.dailyAyahTime,
      TaliaNotificationService.morningAzkarPreferenceKey =>
        state.morningAzkarTime,
      TaliaNotificationService.eveningAzkarPreferenceKey =>
        state.eveningAzkarTime,
      TaliaNotificationService.dailyDuaPreferenceKey => state.dailyDuaTime,
      TaliaNotificationService.kidsReminderPreferenceKey =>
        state.kidsReminderTime,
      TaliaNotificationService.fridayKahfPreferenceKey => state.fridayKahfTime,
      TaliaNotificationService.weeklyImpactPreferenceKey =>
        state.weeklyImpactTime,
      TaliaNotificationService.tahajjudPreferenceKey => state.tahajjudTime,
      TaliaNotificationService.khatmahReminderPreferenceKey =>
        state.khatmahReminderTime,
      _ => time,
    };
    final hourSaved = await _writeInt('${preferenceKey}_hour', time.hour);
    final minuteSaved = await _writeInt('${preferenceKey}_minute', time.minute);
    final persistedTime = _readTime(
      preferenceKey,
      defaultHour: previousTime.hour,
      defaultMinute: previousTime.minute,
    );

    final updatedState = switch (preferenceKey) {
      TaliaNotificationService.dailyReviewPreferenceKey => state.copyWith(
        dailyReviewTime: persistedTime,
      ),
      TaliaNotificationService.streakAlertPreferenceKey => state.copyWith(
        streakAlertTime: persistedTime,
      ),
      TaliaNotificationService.dailyAyahPreferenceKey => state.copyWith(
        dailyAyahTime: persistedTime,
      ),
      TaliaNotificationService.morningAzkarPreferenceKey => state.copyWith(
        morningAzkarTime: persistedTime,
      ),
      TaliaNotificationService.eveningAzkarPreferenceKey => state.copyWith(
        eveningAzkarTime: persistedTime,
      ),
      TaliaNotificationService.dailyDuaPreferenceKey => state.copyWith(
        dailyDuaTime: persistedTime,
      ),
      TaliaNotificationService.kidsReminderPreferenceKey => state.copyWith(
        kidsReminderTime: persistedTime,
      ),
      TaliaNotificationService.fridayKahfPreferenceKey => state.copyWith(
        fridayKahfTime: persistedTime,
      ),
      TaliaNotificationService.weeklyImpactPreferenceKey => state.copyWith(
        weeklyImpactTime: persistedTime,
      ),
      TaliaNotificationService.tahajjudPreferenceKey => state.copyWith(
        tahajjudTime: persistedTime,
      ),
      TaliaNotificationService.khatmahReminderPreferenceKey => state.copyWith(
        khatmahReminderTime: persistedTime,
      ),
      _ => state,
    };

    if (!isClosed) emit(updatedState);
    if (persistedTime != previousTime) await _reschedule(l10n);
    if (!hourSaved || !minuteSaved) {
      _emitFeedback(state, NotificationSettingsFeedback.saveFailed);
    }
  }

  /// Toggles an individual prayer notification in the prayer filter.
  Future<void> togglePrayer(
    String prayerKey,
    bool value, {
    AppLocalizations? l10n,
  }) async {
    final saved = await _writeBool(prayerKey, value);
    if (!saved) {
      _emitFeedback(state, NotificationSettingsFeedback.saveFailed);
      return;
    }
    final persistedValue = value;

    final updatedState = switch (prayerKey) {
      TaliaNotificationService.prayerFajrKey => state.copyWith(
        prayerFajr: persistedValue,
      ),
      TaliaNotificationService.prayerDhuhrKey => state.copyWith(
        prayerDhuhr: persistedValue,
      ),
      TaliaNotificationService.prayerAsrKey => state.copyWith(
        prayerAsr: persistedValue,
      ),
      TaliaNotificationService.prayerMaghribKey => state.copyWith(
        prayerMaghrib: persistedValue,
      ),
      TaliaNotificationService.prayerIshaKey => state.copyWith(
        prayerIsha: persistedValue,
      ),
      _ => state,
    };

    if (!isClosed) emit(updatedState);
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

  Future<bool> requestExactPrayerTimePermission(AppLocalizations l10n) async {
    final granted = await _notificationService
        .requestExactNotificationPermission();
    if (granted) await _reschedule(l10n);
    return granted;
  }

  Future<void> updateQuietHours({
    required int startHour,
    required int endHour,
    AppLocalizations? l10n,
  }) async {
    final previousStart = state.quietHoursStart;
    final previousEnd = state.quietHoursEnd;
    final startSaved = await _writeInt(
      TaliaNotificationService.quietHoursStartKey,
      startHour,
    );
    final endSaved = await _writeInt(
      TaliaNotificationService.quietHoursEndKey,
      endHour,
    );
    final persistedStart =
        _prefs.getInt(TaliaNotificationService.quietHoursStartKey) ??
        previousStart;
    final persistedEnd =
        _prefs.getInt(TaliaNotificationService.quietHoursEndKey) ?? previousEnd;
    if (!isClosed) {
      emit(
        state.copyWith(
          quietHoursStart: persistedStart,
          quietHoursEnd: persistedEnd,
        ),
      );
    }
    if (persistedStart != previousStart || persistedEnd != previousEnd) {
      await _reschedule(l10n);
    }
    if (!startSaved || !endSaved) {
      _emitFeedback(state, NotificationSettingsFeedback.saveFailed);
    }
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
    final scheduled = await _scheduler.refreshNotificationsForSettings(
      effectiveL10n,
      force: true,
    );
    if (!scheduled) {
      _emitFeedback(state, NotificationSettingsFeedback.schedulingFailed);
    }
  }

  Future<bool> _writeBool(String key, bool value) async {
    try {
      final saved = await _prefs.setBool(key, value);
      return saved && _prefs.getBool(key) == value;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _writeString(String key, String value) async {
    try {
      final saved = await _prefs.setString(key, value);
      return saved && _prefs.getString(key) == value;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _writeInt(String key, int value) async {
    try {
      final saved = await _prefs.setInt(key, value);
      return saved && _prefs.getInt(key) == value;
    } catch (_) {
      return false;
    }
  }

  void _emitFeedback(
    NotificationSettingsState nextState,
    NotificationSettingsFeedback feedback,
  ) {
    if (isClosed) return;
    emit(
      nextState.copyWith(
        feedback: feedback,
        feedbackRevision: state.feedbackRevision + 1,
      ),
    );
  }
}
