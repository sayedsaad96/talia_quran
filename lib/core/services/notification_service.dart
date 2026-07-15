import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

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

  // ─── Notification Channel ───────────────────────────────────────────────────
  static const _androidChannel = AndroidNotificationDetails(
    'talia_reminders',
    'تذكيرات تالية',
    channelDescription: 'تذكيرات يومية للمراجعة والحفظ',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFF2E7D4F),
    icon: _notificationIcon,
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
    await configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(_notificationIcon);
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

  Future<void> configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Fallback
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
      notificationDetails: _notificationDetails,
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
      notificationDetails: _notificationDetails,
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
      notificationDetails: _notificationDetails,
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
        notificationDetails: _notificationDetails,
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
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/memorization-plus/kids-journey?surahId=1',
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
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_alert',
          'تنبيه الـ Streak',
          channelDescription: 'تنبيه عند خطر انقطاع التسلسل اليومي',
          importance: Importance.max,
          priority: Priority.high,
          icon: _notificationIcon,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/memorization',
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

  Future<List<String>> _loadDailyDuas() async {
    try {
      final data =
          jsonDecode(await rootBundle.loadString('assets/data/azkar.json'))
              as Map<String, dynamic>;
      final duas = (data['duas'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .map((item) => item['text'] as String? ?? '')
          .where((text) => text.trim().isNotEmpty)
          .map(_compactNotificationText)
          .toList();
      if (duas.isNotEmpty) return duas;
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
