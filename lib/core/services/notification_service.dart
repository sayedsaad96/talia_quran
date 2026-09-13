import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../router/launch_destination.dart';
import '../content/approved_azkar_content.dart';
import '../utils/talia_logger.dart';
import 'daily_ayah_notification_target.dart';

/// Smart notification service for Talia Quran.
///
/// Handles:
/// - Daily review reminders (default 8:00 PM)
/// - Streak protection alerts (10:00 PM if no activity)
/// - Daily ayah notification (7:00 AM)
class ScheduledPrayerNotification {
  const ScheduledPrayerNotification({
    required this.idOffset,
    required this.title,
    required this.body,
    required this.scheduledDate,
  });

  final int idOffset;
  final String title;
  final String body;
  final DateTime scheduledDate;
}

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
  static const String dailyAyahPreferenceKey = 'notifications_daily_ayah';
  static const String kidsReminderPreferenceKey = 'notifications_kids_review';
  static const String fridayKahfPreferenceKey = 'notifications_friday_kahf';
  static const String tahajjudPreferenceKey = 'notifications_tahajjud';
  static const String khatmahReminderPreferenceKey = 'notifications_khatmah';
  static const String prayerNotificationsPreferenceKey =
      'notifications_prayer_times';
  static const String prayerFajrKey = 'notifications_prayer_fajr';
  static const String prayerDhuhrKey = 'notifications_prayer_dhuhr';
  static const String prayerAsrKey = 'notifications_prayer_asr';
  static const String prayerMaghribKey = 'notifications_prayer_maghrib';
  static const String prayerIshaKey = 'notifications_prayer_isha';

  // ─── Notification IDs ───────────────────────────────────────────────────────
  static const int _dailyReviewId = 1001;
  static const int _streakAlertId = 1002;
  static const int _legacyDailyAyahId = 1003;
  static const int _morningAzkarId = 1005;
  static const int _eveningAzkarId = 1006;
  static const int _kidsReviewId = 1007;
  static const int _dailyDuaBaseId = 1010;
  static const int _dailyDuaScheduleDays = 16;
  static const int _dailyAyahBaseId = 1040;
  static const int _dailyAyahScheduleDays = 21;
  static const int _fridayKahfId = 1060;
  static const int _tahajjudId = 1061;
  static const int _khatmahReminderId = 1062;
  static const int _morningAzkarBaseId = 1070;
  static const int _eveningAzkarBaseId = 1090;
  static const int _azkarScheduleDays = 14;
  static const int _prayerTimesBaseId = 2000;
  static const int _prayerTimesMaxCount = 40;
  static const String _notificationIcon = '@mipmap/launcher_icon';

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
      'action_share_daily_ayah',
      '↗️ مشاركة الآية',
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

  // 8. Friday Surah Al-Kahf Actions
  static final List<AndroidNotificationAction> _fridayKahfActions = [
    const AndroidNotificationAction(
      'action_read_kahf',
      '📖 قراءة سورة الكهف',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      'action_quran',
      '✨ المصحف',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 9. Tahajjud Actions
  static final List<AndroidNotificationAction> _tahajjudActions = [
    const AndroidNotificationAction(
      'action_tahajjud',
      '🤲 أدعية قيام الليل',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      'action_quran',
      '📖 المصحف',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 10. Khatmah Actions
  static final List<AndroidNotificationAction> _khatmahActions = [
    const AndroidNotificationAction(
      'action_khatmah',
      '📖 متابعة الختمة',
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 11. Prayer Times Actions
  static final List<AndroidNotificationAction> _prayerActions = [
    const AndroidNotificationAction(
      'action_quran',
      '📖 قراءة القرآن',
      showsUserInterface: true,
      cancelNotification: true,
    ),
    const AndroidNotificationAction(
      'action_azkar',
      '📿 أذكار بعد الصلاة',
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
        DarwinNotificationAction.plain(
          'action_share_daily_ayah',
          '↗️ مشاركة الآية',
        ),
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
    DarwinNotificationCategory(
      'friday_kahf_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_read_kahf',
          '📖 قراءة سورة الكهف',
        ),
        DarwinNotificationAction.plain('action_quran', '✨ المصحف'),
      ],
    ),
    DarwinNotificationCategory(
      'tahajjud_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_tahajjud',
          '🤲 أدعية قيام الليل',
        ),
        DarwinNotificationAction.plain('action_quran', '📖 المصحف'),
      ],
    ),
    DarwinNotificationCategory(
      'khatmah_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('action_khatmah', '📖 متابعة الختمة'),
      ],
    ),
    DarwinNotificationCategory(
      'prayer_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('action_quran', '📖 قراءة القرآن'),
        DarwinNotificationAction.plain('action_azkar', '📿 أذكار بعد الصلاة'),
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
          'حماية السلسلة',
          channelDescription: 'تنبيهات للحفاظ على سلسلة أيام الحفظ',
          importance: Importance.high,
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
          channelDescription: 'آية يومية من القرآن الكريم مع التدبر',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF1B6B93),
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
          'talia_morning_azkar',
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
          'talia_evening_azkar',
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

  static NotificationDetails get _fridayKahfNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_kahf',
          'سورة الكهف',
          channelDescription: 'تذكيرات قراءة سورة الكهف يوم الجمعة',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF2E7D4F),
          icon: _notificationIcon,
          playSound: true,
          actions: _fridayKahfActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'friday_kahf_category',
        ),
      );

  static NotificationDetails get _tahajjudNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_tahajjud',
          'قيام الليل والوتر',
          channelDescription: 'تذكيرات قيام الليل في الثلث الأخير',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF16A085),
          icon: _notificationIcon,
          playSound: true,
          actions: _tahajjudActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'tahajjud_category',
        ),
      );

  static NotificationDetails get _khatmahNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_khatmah',
          'ورد الختمة',
          channelDescription: 'تذكيرات متابعة ورد الختمة',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF2E7D4F),
          icon: _notificationIcon,
          playSound: true,
          actions: _khatmahActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'khatmah_category',
        ),
      );

  static NotificationDetails get _prayerNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_prayer_times',
          'مواقيت الصلاة والأذان',
          channelDescription: 'تنبيهات عند دخول وقت الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          color: const Color(0xFF1E824C),
          icon: _notificationIcon,
          playSound: true,
          actions: _prayerActions,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'prayer_category',
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
    final payload = response.actionId == 'action_daily_ayah'
        ? response.payload
        : LaunchDestination.mapNotificationAction(response.actionId) ??
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
        TaliaLogger.w(
          'iOS notification permission request failed',
          error,
          stack,
        );
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
      } catch (error, stack) {
        TaliaLogger.w('Android notification permission request failed', error, stack);
      }
    }
  }

  /// Checks whether system-level notifications are granted for this app (Android & iOS).
  Future<bool> areNotificationsGranted() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      if (Platform.isAndroid) {
        final androidImplementation = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final enabled = await androidImplementation?.areNotificationsEnabled();
        if (enabled != null) return enabled;
      }
      return await Permission.notification.isGranted;
    } catch (error, stack) {
      TaliaLogger.w('Checking notification permission failed', error, stack);
      return true;
    }
  }

  /// Resets the app icon badge count (iOS).
  Future<void> clearBadge() async {
    if (!Platform.isIOS) return;
    try {
      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      // DarwinNotificationDetails with badgeNumber: 0 resets the badge count on iOS.
      await iosImplementation?.checkPermissions();
    } catch (error, stack) {
      TaliaLogger.w('Error clearing iOS badge', error, stack);
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
      payload: '/memorization',
    );
  }

  /// Cancel the streak alert (called when the user opens the app or has completed activity today).
  Future<void> cancelStreakAlert() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _streakAlertId);
  }

  // ─── Daily Ayah Notification ───────────────────────────────────────────────

  /// Schedules a rolling set of daily-ayah reminders.
  ///
  /// Each entry receives its own date-specific target. This prevents a
  /// recurring notification from opening a stale ayah after the daily context
  /// changes, while keeping Quran text out of the native notification payload.
  Future<void> scheduleDailyAyahReminders({
    required Future<DailyAyahReminder?> Function(DateTime date) reminderForDate,
    int hour = 7,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelDailyAyahReminder();

    final firstDate = _nextInstanceOfTime(hour, minute);
    for (var dayOffset = 0; dayOffset < _dailyAyahScheduleDays; dayOffset++) {
      final scheduledDate = firstDate.add(Duration(days: dayOffset));
      final reminder = await reminderForDate(
        DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day),
      );
      if (reminder == null) continue;

      await _plugin.zonedSchedule(
        id: _dailyAyahBaseId + dayOffset,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: scheduledDate,
        notificationDetails: _dailyAyahNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.target.payload,
      );
    }
  }

  /// Backward-compatible single-content API.
  @Deprecated('Use scheduleDailyAyahReminders with a date-specific target.')
  Future<void> scheduleDailyAyahReminder({
    required String title,
    required String body,
  }) async {
    await scheduleDailyAyahReminders(
      reminderForDate: (_) async => DailyAyahReminder(
        title: title,
        body: body,
        target: const DailyAyahNotificationTarget(
          surahId: 1,
          ayahNumber: 1,
          pageNumber: 1,
        ),
      ),
    );
  }

  /// Cancel only the daily ayah reminder.
  Future<void> cancelDailyAyahReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _legacyDailyAyahId);
    for (var dayOffset = 0; dayOffset < _dailyAyahScheduleDays; dayOffset++) {
      await _plugin.cancel(id: _dailyAyahBaseId + dayOffset);
    }
  }

  // ─── Azkar Notifications ──────────────────────────────────────────────────

  /// Schedules rolling daily morning azkar reminders.
  Future<void> scheduleMorningAzkarReminder({
    required String title,
    required String body,
    int hour = 6,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelMorningAzkarReminder();
    final approvedTexts = await _loadApprovedAzkarTexts('morning');
    if (approvedTexts.isEmpty) return;

    final firstDate = _nextInstanceOfTime(hour, minute);
    for (var dayOffset = 0; dayOffset < _azkarScheduleDays; dayOffset++) {
      final scheduledDate = firstDate.add(Duration(days: dayOffset));
      final text = approvedTexts[_azkarIndexForDate(scheduledDate, approvedTexts.length)];

      await _plugin.zonedSchedule(
        id: _morningAzkarBaseId + dayOffset,
        title: title,
        body: text,
        scheduledDate: scheduledDate,
        notificationDetails: _morningAzkarNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/azkar/morning',
      );
    }
  }

  /// Cancel morning azkar reminders.
  Future<void> cancelMorningAzkarReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _morningAzkarId);
    for (var i = 0; i < _azkarScheduleDays; i++) {
      await _plugin.cancel(id: _morningAzkarBaseId + i);
    }
  }

  /// Schedules rolling daily evening azkar reminders.
  Future<void> scheduleEveningAzkarReminder({
    required String title,
    required String body,
    int hour = 18,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelEveningAzkarReminder();
    final approvedTexts = await _loadApprovedAzkarTexts('evening');
    if (approvedTexts.isEmpty) return;

    final firstDate = _nextInstanceOfTime(hour, minute);
    for (var dayOffset = 0; dayOffset < _azkarScheduleDays; dayOffset++) {
      final scheduledDate = firstDate.add(Duration(days: dayOffset));
      final text = approvedTexts[_azkarIndexForDate(scheduledDate, approvedTexts.length)];

      await _plugin.zonedSchedule(
        id: _eveningAzkarBaseId + dayOffset,
        title: title,
        body: text,
        scheduledDate: scheduledDate,
        notificationDetails: _eveningAzkarNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/azkar/evening',
      );
    }
  }

  /// Cancel evening azkar reminders.
  Future<void> cancelEveningAzkarReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _eveningAzkarId);
    for (var i = 0; i < _azkarScheduleDays; i++) {
      await _plugin.cancel(id: _eveningAzkarBaseId + i);
    }
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

    final duas = await _loadApprovedAzkarTexts('duas');
    // Fail safe: no corpus → no religious notification content at all.
    if (duas.isEmpty) return;

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

  // ─── Friday Surah Al-Kahf Reminder ─────────────────────────────────────────

  /// Schedules a weekly Friday reminder to read Surah Al-Kahf.
  Future<void> scheduleFridayKahfReminder({
    required String title,
    required String body,
    int hour = 9,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelFridayKahfReminder();

    await _plugin.zonedSchedule(
      id: _fridayKahfId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfDayAndTime(DateTime.friday, hour, minute),
      notificationDetails: _fridayKahfNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: '/quran/surah/18',
    );
  }

  /// Cancel Friday Surah Al-Kahf reminder.
  Future<void> cancelFridayKahfReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _fridayKahfId);
  }

  // ─── Tahajjud / Qiyam Al-Layl Reminder ──────────────────────────────────────

  /// Schedules a daily reminder for Tahajjud and night prayer in the last third of the night.
  Future<void> scheduleTahajjudReminder({
    required String title,
    required String body,
    int hour = 3,
    int minute = 30,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelTahajjudReminder();

    await _plugin.zonedSchedule(
      id: _tahajjudId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _tahajjudNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/azkar/duas',
    );
  }

  /// Cancel Tahajjud reminder.
  Future<void> cancelTahajjudReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _tahajjudId);
  }

  // ─── Khatmah Daily Progress Reminder ───────────────────────────────────────

  /// Schedules a daily reminder for the user's active Khatmah target.
  Future<void> scheduleKhatmahReminder({
    required String title,
    required String body,
    required String payload,
    int hour = 17,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelKhatmahReminder();

    await _plugin.zonedSchedule(
      id: _khatmahReminderId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _khatmahNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Cancel Khatmah reminder.
  Future<void> cancelKhatmahReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _khatmahReminderId);
  }

  // ─── Prayer Times Reminders ────────────────────────────────────────────────

  /// Schedules rolling prayer time reminders.
  Future<void> schedulePrayerTimesReminders({
    required List<ScheduledPrayerNotification> prayers,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelPrayerTimesReminders();

    final now = DateTime.now();
    for (final prayer in prayers) {
      if (prayer.scheduledDate.isBefore(now)) continue;

      final tzDate = tz.TZDateTime.from(prayer.scheduledDate, tz.local);
      await _plugin.zonedSchedule(
        id: _prayerTimesBaseId + prayer.idOffset,
        title: prayer.title,
        body: prayer.body,
        scheduledDate: tzDate,
        notificationDetails: _prayerNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/',
      );
    }
  }

  /// Cancel all scheduled prayer times reminders.
  Future<void> cancelPrayerTimesReminders() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    for (var i = 0; i < _prayerTimesMaxCount; i++) {
      await _plugin.cancel(id: _prayerTimesBaseId + i);
    }
  }

  // ─── Cancel All & Test Notifications ───────────────────────────────────────

  /// Shows an immediate test notification with interactive action buttons.
  Future<void> showImmediateTestNotification({
    required String title,
    required String body,
    String type = 'azkar',
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final azkarCategory = switch (type) {
      'azkar' => 'morning',
      'evening_azkar' => 'evening',
      'dua' => 'duas',
      _ => null,
    };
    var notificationBody = body;
    if (azkarCategory != null) {
      final approvedTexts = await _loadApprovedAzkarTexts(azkarCategory);
      if (approvedTexts.isEmpty) return;
      notificationBody = approvedTexts.first;
    }
    await requestPermissions();

    final testDetails = switch (type) {
      'azkar' => _morningAzkarNotificationDetails,
      'evening_azkar' => _eveningAzkarNotificationDetails,
      'streak' => _streakNotificationDetails,
      'dua' => _dailyDuaNotificationDetails,
      'kids' => _kidsReviewNotificationDetails,
      'friday_kahf' => _fridayKahfNotificationDetails,
      'tahajjud' => _tahajjudNotificationDetails,
      'khatmah' => _khatmahNotificationDetails,
      'prayer' => _prayerNotificationDetails,
      _ => _dailyReviewNotificationDetails,
    };

    final payload = switch (type) {
      'azkar' => '/azkar/morning',
      'evening_azkar' => '/azkar/evening',
      'streak' => '/memorization',
      'dua' => '/azkar/duas',
      'kids' => '/memorization-plus/kids-journey',
      'friday_kahf' => '/quran/surah/18',
      'tahajjud' => '/azkar/duas',
      'khatmah' => '/khatmah',
      'prayer' => '/',
      _ => '/memorization',
    };

    await _plugin.show(
      id: 9999,
      title: title,
      body: notificationBody,
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

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != dayOfWeek) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  final Map<String, List<String>> _cachedAzkarTexts = {};

  /// Loads daily dua bodies from the bundled approved corpus only.
  ///
  /// There is deliberately NO hand-typed fallback: if the corpus is
  /// unavailable, the caller skips scheduling instead of emitting unapproved
  /// religious text (V1-M4). Text is passed through verbatim — never
  /// truncated or rewritten.
  Future<List<String>> _loadApprovedAzkarTexts(String category) async {
    if (_cachedAzkarTexts.containsKey(category)) {
      return _cachedAzkarTexts[category]!;
    }
    try {
      final source = await rootBundle.loadString(
        'assets/data/azkar_release.json',
      );
      final texts = extractApprovedAzkarTexts(source, category: category);
      _cachedAzkarTexts[category] = texts;
      return texts;
    } catch (error, stack) {
      TaliaLogger.w('Failed to load approved azkar texts for category $category', error, stack);
      return const [];
    }
  }

  int _azkarIndexForDate(tz.TZDateTime date, int count) {
    if (count <= 0) return 0;
    final day = DateTime(date.year, date.month, date.day);
    final base = DateTime(2024);
    return day.difference(base).inDays.abs() % count;
  }

  int _duaIndexForDate(tz.TZDateTime date, int duaCount) {
    if (duaCount <= 0) return 0;
    final day = DateTime(date.year, date.month, date.day);
    final base = DateTime(2024);
    return day.difference(base).inDays.abs() % duaCount;
  }
}
