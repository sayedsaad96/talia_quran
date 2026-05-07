import 'dart:io';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Smart notification service for Talia Quran.
///
/// Handles:
/// - Daily review reminders (default 8:00 PM)
/// - Streak protection alerts (10:00 PM if no activity)
/// - Daily ayah notification (7:00 AM)
/// - Morning and evening azkar reminders
/// - Smart reminders based on user's average app-open time
class TaliaNotificationService {
  TaliaNotificationService._();
  static final TaliaNotificationService instance = TaliaNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _pendingLaunchPayload;
  void Function(String payload)? onPayloadReceived;

  static const String dailyReviewPreferenceKey = 'notifications_daily_review';
  static const String streakAlertPreferenceKey = 'notifications_streak_alert';
  static const String morningAzkarPreferenceKey = 'notifications_morning_azkar';
  static const String eveningAzkarPreferenceKey = 'notifications_evening_azkar';

  // ─── Notification IDs ───────────────────────────────────────────────────────
  static const int _dailyReviewId = 1001;
  static const int _streakAlertId = 1002;
  static const int _dailyAyahId = 1003;
  static const int _smartReminderId =
      1004; // M04 FIX: Separate ID for smart reminder
  static const int _morningAzkarId = 1005;
  static const int _eveningAzkarId = 1006;

  // ─── Motivational Messages ──────────────────────────────────────────────────
  static const List<String> _motivationalMessages = [
    'القرآن يشتاق إليك! 📖',
    'خطوة صغيرة اليوم، ثواب كبير غداً ✨',
    'جلسة حفظ اليوم تنتظرك 🌙',
    'لا تكسر تسلسلك! 🔥',
    'آية واحدة تبني لك مكانة في الجنة 💎',
    'راجع ما حفظته قبل أن تنسى 📚',
    'اليوم فرصة لإضافة آية جديدة لقلبك 💚',
  ];

  // ─── Notification Channel ───────────────────────────────────────────────────
  static const _androidChannel = AndroidNotificationDetails(
    'talia_reminders',
    'تذكيرات تالية',
    channelDescription: 'تذكيرات يومية للمراجعة والحفظ',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFF2E7D4F),
    icon: '@mipmap/ic_launcher',
    playSound: true,
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidChannel,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
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
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _pendingLaunchPayload = launchDetails?.notificationResponse?.payload;
    }

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty || !payload.startsWith('/')) {
      return;
    }
    onPayloadReceived?.call(payload);
  }

  String? takePendingLaunchPayload() {
    final payload = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return payload;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final String localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (_) {
      // Fallback
    }
  }

  /// Re-schedules all notifications. Useful on app resume or timezone change.
  Future<void> refreshNotifications() async {
    if (!_initialized) return;
    await _configureLocalTimezone();

    final prefs = await SharedPreferences.getInstance();
    final reviewEnabled = prefs.getBool(dailyReviewPreferenceKey) ?? true;
    final morningAzkarEnabled =
        prefs.getBool(morningAzkarPreferenceKey) ?? true;
    final eveningAzkarEnabled =
        prefs.getBool(eveningAzkarPreferenceKey) ?? true;

    if (reviewEnabled) {
      await scheduleDailyReviewReminder();
    } else {
      await cancelDailyReviewReminder();
    }
    await scheduleDailyAyahReminder();

    if (morningAzkarEnabled) {
      await scheduleMorningAzkarReminder();
    } else {
      await cancelMorningAzkarReminder();
    }

    if (eveningAzkarEnabled) {
      await scheduleEveningAzkarReminder();
    } else {
      await cancelEveningAzkarReminder();
    }
  }

  /// Request permissions for local notifications (iOS and Android 13+)
  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // ─── Daily Review Reminder ─────────────────────────────────────────────────

  /// Schedules a daily review reminder at the given hour and minute.
  /// Default: 8:00 PM (20:00).
  Future<void> scheduleDailyReviewReminder({
    int hour = 20,
    int minute = 0,
    int pendingReviewCount = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _dailyReviewId);

    final body = pendingReviewCount > 0
        ? 'لديك $pendingReviewCount آية للمراجعة اليوم'
        : 'حان وقت مراجعة حفظك اليومي';

    await _plugin.zonedSchedule(
      id: _dailyReviewId,
      title: 'وقت المراجعة اليومية 📖',
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/hifz',
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
    required int currentStreak,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (currentStreak <= 0) return;

    await _plugin.cancel(id: _streakAlertId);

    await _plugin.zonedSchedule(
      id: _streakAlertId,
      title: '⚠️ لا تُضيِّع $currentStreak يوماً!',
      body: 'لم تراجع حفظك اليوم بعد — لا تزال قادرًا',
      scheduledDate: _nextInstanceOfTime(22, 0),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/hifz',
    );
  }

  /// Cancel the streak alert (called when the user opens the app).
  Future<void> cancelStreakAlert() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _streakAlertId);
  }

  // ─── Daily Ayah Notification ───────────────────────────────────────────────

  /// Schedules a daily morning ayah reminder at 7:00 AM.
  Future<void> scheduleDailyAyahReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _dailyAyahId);

    await _plugin.zonedSchedule(
      id: _dailyAyahId,
      title: 'آية اليوم ✨',
      body: 'اقرأ وردك اليومي من القرآن الكريم',
      scheduledDate: _nextInstanceOfTime(7, 0),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/quran',
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
    int hour = 6,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _morningAzkarId);

    await _plugin.zonedSchedule(
      id: _morningAzkarId,
      title: 'أذكار الصباح ☀️',
      body: 'ابدأ يومك بذكر الله وطمأنينة القلب',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _notificationDetails,
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
    int hour = 18,
    int minute = 0,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _eveningAzkarId);

    await _plugin.zonedSchedule(
      id: _eveningAzkarId,
      title: 'أذكار المساء 🌙',
      body: 'اختم يومك بذكر الله وحفظه',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _notificationDetails,
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

  // ─── Smart Reminder ────────────────────────────────────────────────────────

  /// Schedules a smart reminder based on the user's average app-open time.
  /// Tracks the last 14 open times and calculates the best reminder time.
  Future<void> scheduleSmartReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final prefs = await SharedPreferences.getInstance();

    // Record current app-open hour
    final currentHour = DateTime.now().hour;
    final storedHours = prefs.getStringList('open_hours') ?? [];
    storedHours.add(currentHour.toString());
    if (storedHours.length > 14) storedHours.removeAt(0);
    await prefs.setStringList('open_hours', storedHours);

    // Calculate average open hour
    int avgHour = 20; // default 8 PM
    if (storedHours.length >= 3) {
      final sum = storedHours.map(int.parse).reduce((a, b) => a + b);
      avgHour = (sum / storedHours.length).round();
    }

    // Pick a non-repeating message
    final usedIndex = prefs.getInt('last_msg_index') ?? 0;
    final nextIndex = (usedIndex + 1) % _motivationalMessages.length;
    await prefs.setInt('last_msg_index', nextIndex);

    // Cancel old and schedule new
    // M04 FIX: Use separate ID so smart reminder doesn't cancel daily ayah
    await _plugin.cancel(id: _smartReminderId);

    final tzNow = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      tzNow.year,
      tzNow.month,
      tzNow.day,
      avgHour,
    );
    if (scheduledTime.isBefore(tzNow)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _smartReminderId, // M04 FIX
      title: 'تالية 📖',
      body: _motivationalMessages[nextIndex],
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'التذكير اليومي',
          channelDescription: 'تذكير يومي لحفظ القرآن',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: 'daily_reminder'),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/hifz',
    );
  }

  // ─── Streak Alert (Smart) ──────────────────────────────────────────────────

  /// Schedules a streak-specific alert at 9 PM for users with streak > 3 days.
  Future<void> scheduleStreakAlert(int currentStreak) async {
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
      title: 'تحذير الـ Streak! 🔥',
      body: 'أيامك الـ $currentStreak على المحك — حافظ على تسلسلك الآن',
      scheduledDate: alertTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_alert',
          'تنبيه الـ Streak',
          channelDescription: 'تنبيه عند خطر انقطاع التسلسل اليومي',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/hifz',
    );
  }

  // ─── Cancel All ────────────────────────────────────────────────────────────

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
}
