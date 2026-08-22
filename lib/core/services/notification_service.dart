import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../router/launch_destination.dart';
import '../utils/talia_logger.dart';

/// Smart notification service for Talia Quran.
///
/// Handles:
/// - Daily review reminders (default 8:00 PM)
/// - Streak protection alerts (10:00 PM if no activity)
/// - Daily ayah notification (7:00 AM)
/// - Morning and evening azkar reminders
class TaliaNotificationService {
  TaliaNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _pendingLaunchPayload;
  String? _pendingLaunchActionId;
  void Function(String payload)? onPayloadReceived;

  static const String dailyReviewPreferenceKey = 'notifications_daily_review';
  static const String streakAlertPreferenceKey = 'notifications_streak_alert';
  static const String morningAzkarPreferenceKey = 'notifications_morning_azkar';
  static const String eveningAzkarPreferenceKey = 'notifications_evening_azkar';
  static const String dailyDuaPreferenceKey = 'notifications_daily_dua';
  static const String kidsReminderPreferenceKey = 'notifications_kids_review';

  // ─── Notification IDs ───────────────────────────────────────────────────────
  static const int _dailyReviewId = 1001;
  static const int _streakAlertId = 1002;
  static const int _dailyAyahId = 1003;
  static const int _morningAzkarId = 1005;
  static const int _eveningAzkarId = 1006;
  static const int _kidsReviewId = 1007;
  static const int _dailyDuaBaseId = 1010;
  static const int _dailyDuaScheduleDays = 16;
  static const String _notificationIcon = '@mipmap/launcher_icon';

  static const List<String> _fallbackDailyDuas = [
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى.',
    'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي.',
  ];

  // ─── Notification Channel & Interactive Actions ──────────────────────────────
  // 1. Daily Review Actions & Category
  static final List<AndroidNotificationAction> _reviewActions = [
    const AndroidNotificationAction(
      'action_review',
      '⚡ ابدأ المراجعة',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      'action_quran',
      '📖 الورد اليومي',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 2. Streak Protection Actions & Category
  static final List<AndroidNotificationAction> _streakActions = [
    const AndroidNotificationAction(
      'action_streak',
      '🔥 احمي السلسلة الآن',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      'action_quran',
      '📖 قراءة الورد',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 3. Daily Ayah Actions & Category
  static final List<AndroidNotificationAction> _dailyAyahActions = [
    const AndroidNotificationAction(
      'action_daily_ayah',
      '✨ قراءة آية اليوم',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      'action_quran',
      '📖 المصحف الشريف',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 4. Morning Azkar Actions & Category
  static final List<AndroidNotificationAction> _morningAzkarActions = [
    const AndroidNotificationAction(
      'action_morning_azkar',
      '☀️ قراءة أذكار الصباح',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      'action_quran',
      '📖 الورد اليومي',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 5. Evening Azkar Actions & Category
  static final List<AndroidNotificationAction> _eveningAzkarActions = [
    const AndroidNotificationAction(
      'action_evening_azkar',
      '🌙 قراءة أذكار المساء',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      'action_quran',
      '📖 الورد اليومي',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 6. Daily Dua Actions & Category
  static final List<AndroidNotificationAction> _dailyDuaActions = [
    const AndroidNotificationAction(
      'action_daily_dua',
      '🤲 قراءة أدعية اليوم',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      'action_azkar',
      '✨ الأذكار',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 7. Kids Review Actions & Category
  static final List<AndroidNotificationAction> _kidsReviewActions = [
    const AndroidNotificationAction(
      'action_kids_review',
      '🌟 ابدأ التسميع يا بطل',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  static final List<DarwinNotificationCategory> _darwinCategories = [
    DarwinNotificationCategory(
      'review_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('action_review', '⚡ ابدأ المراجعة'),
        DarwinNotificationAction.plain('action_quran', '📖 الورد اليومي'),
      ],
    ),
    DarwinNotificationCategory(
      'streak_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('action_streak', '🔥 احمي السلسلة الآن'),
        DarwinNotificationAction.plain('action_quran', '📖 قراءة الورد'),
      ],
    ),
    DarwinNotificationCategory(
      'daily_ayah_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_daily_ayah',
          '✨ قراءة آية اليوم',
        ),
        DarwinNotificationAction.plain('action_quran', '📖 المصحف الشريف'),
      ],
    ),
    DarwinNotificationCategory(
      'morning_azkar_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_morning_azkar',
          '☀️ قراءة أذكار الصباح',
        ),
        DarwinNotificationAction.plain('action_quran', '📖 الورد اليومي'),
      ],
    ),
    DarwinNotificationCategory(
      'evening_azkar_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_evening_azkar',
          '🌙 قراءة أذكار المساء',
        ),
        DarwinNotificationAction.plain('action_quran', '📖 الورد اليومي'),
      ],
    ),
    DarwinNotificationCategory(
      'daily_dua_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_daily_dua',
          '🤲 قراءة أدعية اليوم',
        ),
        DarwinNotificationAction.plain('action_azkar', '✨ الأذكار'),
      ],
    ),
    DarwinNotificationCategory(
      'kids_review_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_kids_review',
          '🌟 ابدأ التسميع يا بطل',
        ),
      ],
    ),
  ];

  static NotificationDetails get _dailyReviewNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_reminders',
          'تذكيرات تالية',
          channelDescription: 'تذكيرات يومية للمراجعة والحفظ',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF2E7D4F),
          icon: _notificationIcon,
          playSound: true,
          actions: _reviewActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'review_category',
        ),
      );

  static NotificationDetails get _streakNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_streak',
          'تنبيهات السلسلة',
          channelDescription: 'تنبيهات حماية السلسلة اليومية',
          importance: Importance.max,
          priority: Priority.high,
          color: const Color(0xFFE67E22),
          icon: _notificationIcon,
          playSound: true,
          actions: _streakActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'streak_category',
        ),
      );

  static NotificationDetails get _dailyAyahNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_daily_ayah',
          'آية اليوم',
          channelDescription: 'تذكيرات قراءة آية اليوم من القرآن الكريم',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF148275),
          icon: _notificationIcon,
          playSound: true,
          actions: _dailyAyahActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'daily_ayah_category',
        ),
      );

  static NotificationDetails get _morningAzkarNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_azkar_morning',
          'أذكار الصباح',
          channelDescription: 'تذكيرات أذكار الصباح',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFF39C12),
          icon: _notificationIcon,
          playSound: true,
          actions: _morningAzkarActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'morning_azkar_category',
        ),
      );

  static NotificationDetails get _eveningAzkarNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_azkar_evening',
          'أذكار المساء',
          channelDescription: 'تذكيرات أذكار المساء',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF8E44AD),
          icon: _notificationIcon,
          playSound: true,
          actions: _eveningAzkarActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'evening_azkar_category',
        ),
      );

  static NotificationDetails get _dailyDuaNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_daily_dua',
          'دعاء اليوم',
          channelDescription: 'تذكيرات دعاء اليوم والابتهالات',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF2980B9),
          icon: _notificationIcon,
          playSound: true,
          actions: _dailyDuaActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'daily_dua_category',
        ),
      );

  static NotificationDetails get _kidsReviewNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_kids',
          'تسميع الأطفال',
          channelDescription: 'تذكيرات مراجعة وتسميع الأطفال',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF27AE60),
          icon: _notificationIcon,
          playSound: true,
          actions: _kidsReviewActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'kids_review_category',
        ),
      );

  /// Initialize the notification system. Must be called on app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    if (!Platform.isAndroid && !Platform.isIOS) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();

    // CODE-3 FIX: Detect and set the device's actual local timezone
    await configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(_notificationIcon);
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: _darwinCategories,
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      _pendingLaunchPayload = response?.payload;
      _pendingLaunchActionId = response?.actionId;
    }

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload =
        LaunchDestination.mapNotificationAction(response.actionId) ??
        response.payload;

    if (payload == null || payload.isEmpty || !payload.startsWith('/')) {
      return;
    }
    onPayloadReceived?.call(payload);
  }

  NotificationLaunchRequest? takePendingLaunch() {
    if (_pendingLaunchPayload == null && _pendingLaunchActionId == null) {
      return null;
    }
    final request = NotificationLaunchRequest(
      payload: _pendingLaunchPayload,
      actionId: _pendingLaunchActionId,
    );
    _pendingLaunchPayload = null;
    _pendingLaunchActionId = null;
    return request;
  }

  @Deprecated('Use takePendingLaunch')
  String? takePendingLaunchPayload() => takePendingLaunch()?.payload;

  Future<void> configureLocalTimezone() async {
    // Some Android OEMs return identifiers ("GMT+03:00") that don't exist in
    // the tz database; swallowing that silently leaves tz.local on UTC and
    // every daily reminder fires hours off. Fall back to the app's primary
    // audience timezone before giving up.
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      return;
    } catch (error, stack) {
      TaliaLogger.w('Device timezone lookup failed', error, stack);
    }
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      TaliaLogger.w('Timezone fallback: using Asia/Riyadh');
    } catch (error, stack) {
      TaliaLogger.w('Timezone fallback failed; staying on UTC', error, stack);
    }
  }

  /// Request permissions for local notifications (iOS and Android 13+)
  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } catch (error, stack) {
        // Mirrors the Android branch: a plugin failure here must never
        // escape — this runs unawaited during startup.
        TaliaLogger.w('iOS notification permission request failed', error, stack);
      }
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      // The Android permission call needs a foreground Activity; it throws
      // when invoked from a background isolate, so never let it escape.
      try {
        await androidImplementation?.requestNotificationsPermission();
      } catch (_) {
        // Permission can still be requested later from the settings screen.
      }
    }
  }

  // ─── Daily Review Reminder ─────────────────────────────────────────────────

  /// Schedules a daily review reminder at the given hour and minute.
  /// Default: 8:00 PM (20:00).
  Future<void> scheduleDailyReviewReminder({
    required String title,
    required String body,
    int hour = 20,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _dailyReviewId);

    await _plugin.zonedSchedule(
      id: _dailyReviewId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _dailyReviewNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/memorization',
    );
  }

  /// Cancel only the daily review reminder.
  Future<void> cancelDailyReviewReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _dailyReviewId);
  }

  // ─── Streak Protection Alert ───────────────────────────────────────────────

  /// Schedules a streak protection alert at 10:00 PM.
  /// Only fires if the user hasn't opened the app today.
  Future<void> scheduleStreakProtectionAlert({
    required String title,
    required String body,
    required int currentStreak,
    int hour = 22,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (currentStreak <= 0) return;

    await _plugin.cancel(id: _streakAlertId);

    await _plugin.zonedSchedule(
      id: _streakAlertId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _streakNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/memorization',
    );
  }

  /// Cancel the streak alert (called when the user opens the app).
  Future<void> cancelStreakAlert() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _streakAlertId);
  }

  // ─── Daily Ayah Notification ───────────────────────────────────────────────

  /// Schedules a daily morning ayah reminder at 7:00 AM.
  Future<void> scheduleDailyAyahReminder({
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _dailyAyahId);

    await _plugin.zonedSchedule(
      id: _dailyAyahId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(7, 0),
      notificationDetails: _dailyAyahNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/quran/daily',
    );
  }

  /// Cancel only the daily ayah reminder.
  Future<void> cancelDailyAyahReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _dailyAyahId);
  }

  // ─── Azkar Notifications ──────────────────────────────────────────────────

  /// Schedules a daily morning azkar reminder at 6:00 AM.
  Future<void> scheduleMorningAzkarReminder({
    required String title,
    required String body,
    int hour = 6,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _morningAzkarId);

    await _plugin.zonedSchedule(
      id: _morningAzkarId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _morningAzkarNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/azkar/morning',
    );
  }

  /// Cancel only the morning azkar reminder.
  Future<void> cancelMorningAzkarReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _morningAzkarId);
  }

  /// Schedules a daily evening azkar reminder at 6:00 PM.
  Future<void> scheduleEveningAzkarReminder({
    required String title,
    required String body,
    int hour = 18,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _eveningAzkarId);

    await _plugin.zonedSchedule(
      id: _eveningAzkarId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _eveningAzkarNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/azkar/evening',
    );
  }

  /// Cancel only the evening azkar reminder.
  Future<void> cancelEveningAzkarReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _eveningAzkarId);
  }

  /// Schedules rolling daily dua notifications at 9:00 AM.
  ///
  /// A recurring notification would keep the same body forever, so this schedules
  /// the next several days individually and refreshes them when the app resumes.
  Future<void> scheduleDailyDuaReminder({
    required String title,
    int hour = 9,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelDailyDuaReminder();

    final duas = await _loadDailyDuas();
    final firstDate = _nextInstanceOfTime(hour, minute);

    for (var dayOffset = 0; dayOffset < _dailyDuaScheduleDays; dayOffset++) {
      final scheduledDate = firstDate.add(Duration(days: dayOffset));
      final body = duas[_duaIndexForDate(scheduledDate, duas.length)];

      await _plugin.zonedSchedule(
        id: _dailyDuaBaseId + dayOffset,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _dailyDuaNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/azkar/duas',
      );
    }
  }

  Future<void> cancelDailyDuaReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    for (var dayOffset = 0; dayOffset < _dailyDuaScheduleDays; dayOffset++) {
      await _plugin.cancel(id: _dailyDuaBaseId + dayOffset);
    }
  }

  Future<void> scheduleKidsReviewReminder({
    required String title,
    required String body,
    int hour = 18,
    int minute = 30,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _kidsReviewId);

    await _plugin.zonedSchedule(
      id: _kidsReviewId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _kidsReviewNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/memorization-plus/kids-journey',
    );
  }

  Future<void> cancelKidsReviewReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _kidsReviewId);
  }

  // ─── Streak Alert (Smart) ──────────────────────────────────────────────────

  /// Schedules a streak-specific alert at 9 PM for users with streak > 3 days.
  Future<void> scheduleStreakAlert({
    required String title,
    required String body,
    required int currentStreak,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (currentStreak <= 3) return;

    await _plugin.cancel(id: _streakAlertId);

    final tzNow = tz.TZDateTime.now(tz.local);
    var alertTime = tz.TZDateTime(
      tz.local,
      tzNow.year,
      tzNow.month,
      tzNow.day,
      21,
      0,
    );
    if (alertTime.isBefore(tzNow)) {
      alertTime = alertTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _streakAlertId,
      title: title,
      body: body,
      scheduledDate: alertTime,
      notificationDetails: _streakNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/memorization',
    );
  }

  // ─── Cancel All & Test Notifications ───────────────────────────────────────

  /// Shows an immediate test notification with interactive action buttons.
  Future<void> showImmediateTestNotification({
    required String title,
    required String body,
    String type = 'azkar',
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await requestPermissions();

    final testDetails = switch (type) {
      'azkar' => _morningAzkarNotificationDetails,
      'evening_azkar' => _eveningAzkarNotificationDetails,
      'streak' => _streakNotificationDetails,
      'dua' => _dailyDuaNotificationDetails,
      'kids' => _kidsReviewNotificationDetails,
      _ => _dailyReviewNotificationDetails,
    };

    final payload = switch (type) {
      'azkar' => '/azkar/morning',
      'evening_azkar' => '/azkar/evening',
      'streak' => '/memorization',
      'dua' => '/azkar/duas',
      'kids' => '/memorization-plus/kids-journey',
      _ => '/memorization',
    };

    await _plugin.show(
      id: 9999,
      title: title,
      body: body,
      notificationDetails: testDetails,
      payload: payload,
    );
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancelAll();
  }

  // ─── Helper ────────────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  List<String>? _cachedDuas;

  Future<List<String>> _loadDailyDuas() async {
    if (_cachedDuas != null && _cachedDuas!.isNotEmpty) return _cachedDuas!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/azkar.json');
      final data = await compute(
        (String str) => jsonDecode(str) as Map<String, dynamic>,
        jsonStr,
      );
      final duas = (data['duas'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .map((item) => item['text'] as String? ?? '')
          .where((text) => text.trim().isNotEmpty)
          .map(_compactNotificationText)
          .toList();
      if (duas.isNotEmpty) {
        _cachedDuas = duas;
        return duas;
      }
    } catch (_) {
      // Keep notification scheduling resilient if assets are unavailable.
    }

    return _fallbackDailyDuas;
  }

  int _duaIndexForDate(tz.TZDateTime date, int duaCount) {
    final day = DateTime(date.year, date.month, date.day);
    final base = DateTime(2024);
    return day.difference(base).inDays % duaCount;
  }

  String _compactNotificationText(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 180) return compact;
    return '${compact.substring(0, 177)}...';
  }
}
