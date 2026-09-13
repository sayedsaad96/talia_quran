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

  Future<void> _refreshNotifications(
    AppLocalizations l10n, {
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // First, sync timezone
    await _service.configureLocalTimezone();

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

      await _service.scheduleDailyReviewReminder(
        title: l10n.notificationDailyReviewTitle,
        body: body,
        hour: hour,
        minute: minute,
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
      await _service.scheduleStreakProtectionAlert(
        title: l10n.notificationStreakAlertTitle(currentStreak),
        body: l10n.notificationStreakAlertBody,
        currentStreak: currentStreak,
        hour: hour,
        minute: minute,
      );
    } else {
      await _service.cancelStreakAlert();
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
        await _service.scheduleDailyAyahReminders(
          hour: hour,
          minute: minute,
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
          hour: hour,
          minute: minute,
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
          hour: hour,
          minute: minute,
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
          hour: hour,
          minute: minute,
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
        hour: hour,
        minute: minute,
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
      await _service.scheduleFridayKahfReminder(
        title: l10n.notificationFridayKahfTitle,
        body: l10n.notificationFridayKahfBody,
        hour: hour,
        minute: minute,
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
      await _service.scheduleTahajjudReminder(
        title: l10n.notificationTahajjudTitle,
        body: l10n.notificationTahajjudBody,
        hour: hour,
        minute: minute,
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
        final usecase = _getActiveKhatmah ??
            (getIt.isRegistered<GetActiveKhatmahUsecase>()
                ? getIt<GetActiveKhatmahUsecase>()
                : null);
        activePlan = await usecase?.call();
      } catch (e, stack) {
        TaliaLogger.w('Failed to load active khatmah for notification', e, stack);
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

      await _service.scheduleKhatmahReminder(
        title: l10n.notificationKhatmahTitle,
        body: body,
        payload: payload,
        hour: hour,
        minute: minute,
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
    if (prayerTimesEnabled) {
      if (shouldRefreshRolling) {
        try {
          final prayerService = _prayerTimesService ??
              (getIt.isRegistered<PrayerTimesService>()
                  ? getIt<PrayerTimesService>()
                  : null);
          if (prayerService != null) {
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
                      title: l10n.notificationPrayerTitle(prayerName),
                      body: l10n.notificationPrayerBody,
                      scheduledDate: prayer.time,
                    ),
                  );
                }
                offset++;
              }
            }
            await _service.schedulePrayerTimesReminders(
              prayers: scheduledPrayers,
            );
          }
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
  }
}
