import 'package:shared_preferences/shared_preferences.dart';
import '../di/injection.dart';
import '../l10n/app_localizations.dart';
import '../services/streak_reader.dart';
import '../services/streak_risk_evaluator.dart';
import '../utils/talia_logger.dart';
import '../../features/progress/domain/repositories/progress_repository.dart';
import '../../features/home/domain/usecases/get_ayah_of_day_usecase.dart';
import '../../features/khatmah/domain/entities/khatmah_plan.dart';
import '../../features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';

import 'daily_ayah_notification_target.dart';
import 'notification_service.dart';
import 'prayer_times_service.dart';

typedef KidsSessionDatesLoader = Future<List<DateTime>> Function();

bool hasCompletedKidsMissionToday(
  Iterable<DateTime> completedAt, {
  DateTime? now,
}) {
  final localNow = (now ?? DateTime.now()).toLocal();
  return completedAt.any((date) {
    final localDate = date.toLocal();
    return localDate.year == localNow.year &&
        localDate.month == localNow.month &&
        localDate.day == localNow.day;
  });
}

/// Pure quiet-hours helper: if [hour]/[minute] falls inside the quiet window
/// ([startHour]..[endHour], possibly wrapping midnight), returns the first
/// time AFTER the window ends (endHour:00). Otherwise returns the input
/// unchanged. When [enabled] is false the input is always returned unchanged.
bool _isInQuietWindow(int hour, int startHour, int endHour) {
  if (startHour == endHour) return true; // degenerate window covers all day
  if (startHour < endHour) {
    return hour >= startHour && hour < endHour;
  }
  // Wraps midnight (e.g. 23 -> 4).
  return hour >= startHour || hour < endHour;
}

({int hour, int minute}) applyQuietHours({
  required int hour,
  required int minute,
  required bool enabled,
  required int startHour,
  required int endHour,
}) {
  if (!enabled) return (hour: hour, minute: minute);
  if (!_isInQuietWindow(hour, startHour, endHour)) {
    return (hour: hour, minute: minute);
  }
  return (hour: endHour % 24, minute: 0);
}

class NotificationScheduler {
  final TaliaNotificationService _service;
  final KidsSessionDatesLoader? _kidsSessionDatesLoader;
  final GetAyahOfDayUsecase? _getAyahOfDay;
  final StreakRiskEvaluator _streakRiskEvaluator;
  final PrayerTimesService? _prayerTimesService;
  final GetActiveKhatmahUsecase? _getActiveKhatmah;

  NotificationScheduler(
    this._service, {
    KidsSessionDatesLoader? kidsSessionDatesLoader,
    GetAyahOfDayUsecase? getAyahOfDay,
    StreakRiskEvaluator streakRiskEvaluator = const StreakRiskEvaluator(),
    PrayerTimesService? prayerTimesService,
    GetActiveKhatmahUsecase? getActiveKhatmah,
  }) : _kidsSessionDatesLoader = kidsSessionDatesLoader,
       _getAyahOfDay = getAyahOfDay,
       _streakRiskEvaluator = streakRiskEvaluator,
       _prayerTimesService = prayerTimesService,
       _getActiveKhatmah = getActiveKhatmah;

  String? _lastRollingDateKey;

  /// Reschedules every enabled reminder. Called from app resume, locale
  /// changes and first launch — none of which may surface plugin errors,
  /// so any failure is logged and contained.
  Future<void> refreshNotifications(
    AppLocalizations l10n, {
    bool force = false,
  }) async {
    try {
      await _refreshNotifications(l10n, force: force);
    } catch (error, stack) {
      TaliaLogger.w('Notification refresh failed', error, stack);
    }
  }

  /// Background refreshes need a success signal so WorkManager can retry a
  /// failed rolling-schedule update instead of treating it as complete.
  Future<bool> refreshNotificationsInBackground(
    AppLocalizations l10n, {
    bool force = false,
  }) async {
    try {
      await _refreshNotifications(l10n, force: force);
      return true;
    } catch (error, stack) {
      TaliaLogger.w('Background notification refresh failed', error, stack);
      return false;
    }
  }

  Future<void> _refreshNotifications(
    AppLocalizations l10n, {
    bool force = false,
  }) async {
    // Keep notification action labels / channel names in the active locale.
    _service.attachLocalization(l10n);

    final prefs = await SharedPreferences.getInstance();

    // Every refresh call corresponds to an app open/resume: record the hour
    // for the smart reminder heuristic.
    await recordAppOpen();

    // First, sync timezone
    await _service.configureLocalTimezone();

    final quietEnabled =
        prefs.getBool(TaliaNotificationService.quietHoursPreferenceKey) ??
        false;
    final quietStartHour =
        prefs.getInt(TaliaNotificationService.quietHoursStartKey) ?? 23;
    final quietEndHour =
        prefs.getInt(TaliaNotificationService.quietHoursEndKey) ?? 4;
    ({int hour, int minute}) quiet(int hour, int minute) => applyQuietHours(
      hour: hour,
      minute: minute,
      enabled: quietEnabled,
      startHour: quietStartHour,
      endHour: quietEndHour,
    );

    int currentStreak = 1;
    int dueReviews = 0;
    var kidsMissionCompletedToday = false;
    var hasStreakActivityToday = false;

    try {
      if (getIt.isRegistered<StreakReader>()) {
        final streakEntity = await getIt<StreakReader>().getStreak();
        currentStreak = streakEntity.currentStreak;
        final risk = _streakRiskEvaluator.evaluate(streakEntity);
        hasStreakActivityToday = risk.hasActivityToday;
      }
      if (getIt.isRegistered<ProgressRepository>()) {
        final progressResult = await getIt<ProgressRepository>()
            .getOverallProgress();
        progressResult.fold((_) => null, (p) => dueReviews = p.reviewAyahs);
      }
      final kidsDates = await _kidsSessionDatesLoader?.call();
      if (kidsDates != null) {
        kidsMissionCompletedToday = hasCompletedKidsMissionToday(kidsDates);
      }
    } catch (e, stack) {
      TaliaLogger.w('Notification data loading failed', e, stack);
    }

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
    final dailyAyahEnabled =
        prefs.getBool(TaliaNotificationService.dailyAyahPreferenceKey) ?? true;
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

      final body = dueReviews > 0
          ? l10n.notificationDailyReviewBodyCount(dueReviews)
          : l10n.notificationDailyReviewBody;

      final quietTime = quiet(hour, minute);
      await _service.scheduleDailyReviewReminder(
        title: l10n.notificationDailyReviewTitle,
        body: body,
        hour: quietTime.hour,
        minute: quietTime.minute,
      );
    } else {
      await _service.cancelDailyReviewReminder();
    }

    if (streakEnabled && !hasStreakActivityToday && currentStreak > 0) {
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

      // Stage 1: gentle nudge one hour before the urgent alert.
      if (hour > 0) {
        await _service.scheduleStreakGentleNudge(
          title: l10n.notificationStreakGentleTitle(currentStreak),
          body: l10n.notificationStreakGentleBody,
          currentStreak: currentStreak,
          hour: hour - 1,
          minute: minute,
        );
      }

      // Stage 2: urgent high-importance protection alert.
      await _service.scheduleStreakProtectionAlert(
        title: l10n.notificationStreakAlertTitle(currentStreak),
        body: l10n.notificationStreakAlertBody,
        currentStreak: currentStreak,
        hour: hour,
        minute: minute,
      );
    } else {
      await _service.cancelStreakAlert();
      await _service.cancelStreakGentleNudge();
    }

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final shouldRefreshRolling = force || _lastRollingDateKey != todayKey;

    if (dailyAyahEnabled && _getAyahOfDay != null) {
      if (shouldRefreshRolling) {
        final hour =
            prefs.getInt(
              '${TaliaNotificationService.dailyAyahPreferenceKey}_hour',
            ) ??
            7;
        final minute =
            prefs.getInt(
              '${TaliaNotificationService.dailyAyahPreferenceKey}_minute',
            ) ??
            0;
        final userGoal = prefs.getString('user_primary_goal');
        final quietTime = quiet(hour, minute);
        await _service.scheduleDailyAyahReminders(
          hour: quietTime.hour,
          minute: quietTime.minute,
          reminderForDate: (date) async {
            final ayah = await _getAyahOfDay(date: date, userGoal: userGoal);
            if (ayah == null) return null;
            return DailyAyahReminder(
              title: l10n.notificationDailyAyahTitle,
              body: l10n.notificationDailyAyahBody,
              target: DailyAyahNotificationTarget(
                surahId: ayah.surahId,
                ayahNumber: ayah.ayahNumber,
                pageNumber: ayah.pageNumber,
              ),
            );
          },
        );
      }
    } else {
      await _service.cancelDailyAyahReminder();
    }

    if (morningAzkarEnabled) {
      if (shouldRefreshRolling) {
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
          hour: quiet(hour, minute).hour,
          minute: quiet(hour, minute).minute,
        );
      }
    } else {
      await _service.cancelMorningAzkarReminder();
    }

    if (eveningAzkarEnabled) {
      if (shouldRefreshRolling) {
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
          hour: quiet(hour, minute).hour,
          minute: quiet(hour, minute).minute,
        );
      }
    } else {
      await _service.cancelEveningAzkarReminder();
    }

    if (dailyDuaEnabled) {
      if (shouldRefreshRolling) {
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
          hour: quiet(hour, minute).hour,
          minute: quiet(hour, minute).minute,
        );
      }
    } else {
      await _service.cancelDailyDuaReminder();
    }

    if (kidsReviewEnabled && !kidsMissionCompletedToday) {
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
        hour: quiet(hour, minute).hour,
        minute: quiet(hour, minute).minute,
      );
    } else {
      await _service.cancelKidsReviewReminder();
    }

    // Friday Surah Al-Kahf Reminder
    final fridayKahfEnabled =
        prefs.getBool(TaliaNotificationService.fridayKahfPreferenceKey) ?? true;
    if (fridayKahfEnabled) {
      final hour =
          prefs.getInt(
            '${TaliaNotificationService.fridayKahfPreferenceKey}_hour',
          ) ??
          9;
      final minute =
          prefs.getInt(
            '${TaliaNotificationService.fridayKahfPreferenceKey}_minute',
          ) ??
          0;
      final quietTime = quiet(hour, minute);
      await _service.scheduleFridayKahfReminder(
        title: l10n.notificationFridayKahfTitle,
        body: l10n.notificationFridayKahfBody,
        hour: quietTime.hour,
        minute: quietTime.minute,
      );
    } else {
      await _service.cancelFridayKahfReminder();
    }

    // Tahajjud / Qiyam Al-Layl Reminder
    final tahajjudEnabled =
        prefs.getBool(TaliaNotificationService.tahajjudPreferenceKey) ?? false;
    if (tahajjudEnabled) {
      final hour =
          prefs.getInt(
            '${TaliaNotificationService.tahajjudPreferenceKey}_hour',
          ) ??
          3;
      final minute =
          prefs.getInt(
            '${TaliaNotificationService.tahajjudPreferenceKey}_minute',
          ) ??
          30;
      final quietTime = quiet(hour, minute);
      await _service.scheduleTahajjudReminder(
        title: l10n.notificationTahajjudTitle,
        body: l10n.notificationTahajjudBody,
        hour: quietTime.hour,
        minute: quietTime.minute,
      );
    } else {
      await _service.cancelTahajjudReminder();
    }

    // Khatmah Daily Progress Reminder
    final khatmahEnabled =
        prefs.getBool(TaliaNotificationService.khatmahReminderPreferenceKey) ??
        true;
    if (khatmahEnabled) {
      final hour =
          prefs.getInt(
            '${TaliaNotificationService.khatmahReminderPreferenceKey}_hour',
          ) ??
          17;
      final minute =
          prefs.getInt(
            '${TaliaNotificationService.khatmahReminderPreferenceKey}_minute',
          ) ??
          0;

      KhatmahPlan? activePlan;
      try {
        final usecase =
            _getActiveKhatmah ??
            (getIt.isRegistered<GetActiveKhatmahUsecase>()
                ? getIt<GetActiveKhatmahUsecase>()
                : null);
        activePlan = await usecase?.call();
      } catch (e, stack) {
        TaliaLogger.w(
          'Failed to load active khatmah for notification',
          e,
          stack,
        );
      }

      final String body;
      final String payload;
      if (activePlan != null &&
          !activePlan.isComplete &&
          activePlan.status == KhatmahStatus.active) {
        final target = activePlan.dailyTargetFor(now);
        body = l10n.notificationKhatmahBodyWithTarget(
          target.startPage,
          target.endPage,
        );
        payload = '/quran/page/${target.startPage}?mode=khatmah';
      } else {
        body = l10n.notificationKhatmahBody;
        payload = '/khatmah';
      }

      final quietTime = quiet(hour, minute);
      await _service.scheduleKhatmahReminder(
        title: l10n.notificationKhatmahTitle,
        body: body,
        payload: payload,
        hour: quietTime.hour,
        minute: quietTime.minute,
      );
    } else {
      await _service.cancelKhatmahReminder();
    }

    // Prayer Times (Rolling 7 Days)
    final prayerTimesEnabled =
        prefs.getBool(
          TaliaNotificationService.prayerNotificationsPreferenceKey,
        ) ??
        false;
    final prayerService =
        _prayerTimesService ??
        (getIt.isRegistered<PrayerTimesService>()
            ? getIt<PrayerTimesService>()
            : null);
    final canSchedulePrayerNotifications =
        prayerTimesEnabled &&
        prayerService != null &&
        prayerService.isReadyForNotificationScheduling;
    if (canSchedulePrayerNotifications) {
      if (shouldRefreshRolling) {
        try {
          final scheduledPrayers = <ScheduledPrayerNotification>[];
          final fajrActive =
              prefs.getBool(TaliaNotificationService.prayerFajrKey) ?? true;
          final dhuhrActive =
              prefs.getBool(TaliaNotificationService.prayerDhuhrKey) ?? true;
          final asrActive =
              prefs.getBool(TaliaNotificationService.prayerAsrKey) ?? true;
          final maghribActive =
              prefs.getBool(TaliaNotificationService.prayerMaghribKey) ?? true;
          final ishaActive =
              prefs.getBool(TaliaNotificationService.prayerIshaKey) ?? true;

          final prayerFilter = {
            'fajr': fajrActive,
            'dhuhr': dhuhrActive,
            'asr': asrActive,
            'maghrib': maghribActive,
            'isha': ishaActive,
          };

          var offset = 0;
          for (var day = 0; day < 7; day++) {
            final targetDate = now.add(Duration(days: day));
            final prayers = await prayerService.timesForDate(targetDate);
            for (final prayer in prayers) {
              if (prayerFilter[prayer.key] == true) {
                final prayerName = l10n.localeName.startsWith('ar')
                    ? prayer.nameAr
                    : prayer.nameEn;
                scheduledPrayers.add(
                  ScheduledPrayerNotification(
                    idOffset: offset,
                    prayerKey: prayer.key,
                    title: l10n.notificationPrayerTitle(prayerName),
                    body: l10n.notificationPrayerBody,
                    scheduledDate: prayer.time,
                  ),
                );
              }
              offset++;
            }
          }
          final athanEnabled =
              prefs.getBool(TaliaNotificationService.prayerAthanKey) ?? false;
          await _service.schedulePrayerTimesReminders(
            prayers: scheduledPrayers,
            athanEnabled: athanEnabled,
          );
        } catch (e, stack) {
          TaliaLogger.w(
            'Failed to schedule prayer times notifications',
            e,
            stack,
          );
        }
      }
    } else {
      await _service.cancelPrayerTimesReminders();
    }

    if (shouldRefreshRolling) {
      _lastRollingDateKey = todayKey;
    }

    // Smart Reminder (greenfield): schedule at the user's most frequent
    // app-open hour when they have a streak but no activity today.
    final smartEnabled =
        prefs.getBool(TaliaNotificationService.smartReminderPreferenceKey) ??
        false;
    if (smartEnabled && !hasStreakActivityToday) {
      final openHours = _loadRecordedOpenHours(prefs);
      if (openHours.length >= 3) {
        await _service.scheduleSmartReminder(
          title: l10n.notificationSmartReminderTitle,
          body: l10n.notificationSmartReminderBody,
          hour: _modeOfOpenHours(openHours),
          minute: 0,
        );
      } else {
        await _service.cancelSmartReminder();
      }
    } else {
      await _service.cancelSmartReminder();
    }
  }

  static const String _smartReminderOpenHoursKey = 'smart_reminder_open_hours';
  static const int _smartReminderMaxEntries = 7;

  /// Records the current local hour of an app open/resume for the smart
  /// reminder heuristic. Keeps the last 7 entries, collapsing consecutive
  /// duplicate hour entries to one.
  Future<void> recordAppOpen({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentHour = (now ?? DateTime.now()).toLocal().hour.toString();
      final entries =
          prefs.getStringList(_smartReminderOpenHoursKey) ?? <String>[];
      // Collapse consecutive duplicates (same hour opened repeatedly).
      if (entries.isEmpty || entries.last != currentHour) {
        entries.add(currentHour);
      }
      while (entries.length > _smartReminderMaxEntries) {
        entries.removeAt(0);
      }
      await prefs.setStringList(_smartReminderOpenHoursKey, entries);
    } catch (error, stack) {
      TaliaLogger.w('Failed to record app open hour', error, stack);
    }
  }

  List<int> _loadRecordedOpenHours(SharedPreferences prefs) {
    final entries =
        prefs.getStringList(_smartReminderOpenHoursKey) ?? <String>[];
    return entries
        .map((entry) => int.tryParse(entry))
        .whereType<int>()
        .where((hour) => hour >= 0 && hour < 24)
        .toList();
  }

  /// Most frequent hour; ties resolved by the most recent occurrence.
  static int _modeOfOpenHours(List<int> hours) {
    final counts = <int, int>{};
    final lastSeen = <int, int>{};
    for (var i = 0; i < hours.length; i++) {
      counts[hours[i]] = (counts[hours[i]] ?? 0) + 1;
      lastSeen[hours[i]] = i;
    }
    int best = hours.first;
    for (final hour in counts.keys) {
      if (counts[hour]! > counts[best]! ||
          (counts[hour] == counts[best] && lastSeen[hour]! > lastSeen[best]!)) {
        best = hour;
      }
    }
    return best;
  }
}
