import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../l10n/app_localizations.dart';
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

/// Returns the lowest-priority scheduled notification IDs that should be
/// removed to make room for [incomingCount] notifications within [limit].
/// Prayer IDs are never evicted; date-specific content is trimmed before
/// recurring, user-configured reminders.
List<int> notificationIdsToCancelForBudget({
  required Iterable<int> pendingIds,
  required int incomingCount,
  required int limit,
}) {
  final ids = pendingIds.toList();
  final needed = math.max(0, ids.length + incomingCount - limit);
  if (needed == 0) return const [];

  int priority(int id) {
    if (id >= 2000 && id < 2040) return 0; // prayer times: never evict
    if (id >= 1040 && id < 1061) return 1; // daily ayah
    if (id >= 1070 && id < 1084) return 2; // morning azkar
    if (id >= 1090 && id < 1104) return 3; // evening azkar
    if (id >= 1010 && id < 1026) return 4; // daily duas
    if (id == 1009) return 5; // smart reminder
    return 0; // recurring/user-configured notifications stay protected
  }

  final candidates = ids.where((id) => priority(id) > 0).toList()
    ..sort((a, b) => priority(b).compareTo(priority(a)));
  return candidates.take(needed).toList(growable: false);
}

/// - Morning and evening azkar reminders
class TaliaNotificationService {
  TaliaNotificationService();

  static const MethodChannel _badgeChannel = MethodChannel('talia/badge');
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  AppLocalizations? _attachedL10n;
  String? _pendingLaunchPayload;
  String? _pendingLaunchActionId;
  void Function(String payload)? onPayloadReceived;

  /// Localization used for action-button labels and channel names. The
  /// scheduler attaches the current locale at the top of every refresh so
  /// labels always follow the active language.
  void attachLocalization(AppLocalizations l10n) {
    _attachedL10n = l10n;
  }

  /// Localization for notification UI strings. Falls back to Arabic (the
  /// app's primary audience language) when no localization was attached.
  AppLocalizations get _effectiveL10n =>
      _attachedL10n ?? lookupAppLocalizations(const Locale('ar'));

  /// Whether exact alarms can be scheduled (Android 12+). On iOS and other
  /// platforms exact scheduling is always available.
  Future<bool> canScheduleExactNotifications() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canSchedule = await androidImplementation
          ?.canScheduleExactNotifications();
      return canSchedule ?? true;
    } catch (error, stack) {
      TaliaLogger.w('Exact alarm capability check failed', error, stack);
      return false;
    }
  }

  /// Resolves the schedule mode for time-critical reminders (prayer times,
  /// streak alerts): exact when the OS allows it, inexact otherwise.
  Future<AndroidScheduleMode> resolveTimeCriticalScheduleMode(
    String label,
  ) async {
    final exact = await canScheduleExactNotifications();
    TaliaLogger.i(
      'Notification schedule mode for $label: '
      '${exact ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle'}',
    );
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Opens Android's special-access flow for exact alarms when required for
  /// prayer-time precision. Other platforms do not need this permission.
  Future<bool> requestExactNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted || await canScheduleExactNotifications();
    } catch (error, stack) {
      TaliaLogger.w('Exact alarm permission request failed', error, stack);
      return false;
    }
  }

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
  static const String quietHoursPreferenceKey = 'notifications_quiet_hours';
  static const String quietHoursStartKey = 'notifications_quiet_start';
  static const String quietHoursEndKey = 'notifications_quiet_end';
  static const String smartReminderPreferenceKey = 'notifications_smart';
  static const String lastKnownTimezonePreferenceKey =
      'notifications_last_known_timezone';

  // ─── Notification IDs ───────────────────────────────────────────────────────
  static const int _dailyReviewId = 1001;
  static const int _streakAlertId = 1002;
  static const int _streakGentleId = 1008;
  static const int _smartReminderId = 1009;
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
  static const int _milestoneCelebrationId = 1100;
  static const int _morningAzkarBaseId = 1070;
  static const int _eveningAzkarBaseId = 1090;
  static const int _azkarScheduleDays = 14;
  static const int _prayerTimesBaseId = 2000;
  static const int _prayerTimesMaxCount = 40;
  // iOS only keeps 64 pending local notifications. Leave headroom for
  // notifications created outside this service and never ask the OS to trim
  // them silently.
  static const int _iOSSafePendingNotificationLimit = 60;
  static const String _notificationIcon = '@mipmap/launcher_icon';

  // ─── Notification Channel & Interactive Actions ──────────────────────────────
  // All action labels and channel names resolve through the attached
  // localization so they follow the active app language.
  AppLocalizations get _l10n => _effectiveL10n;

  Future<int> _availableScheduledNotificationSlots() async {
    if (!Platform.isIOS) return 1 << 30;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final available = math.max(
        0,
        _iOSSafePendingNotificationLimit - pending.length,
      );
      TaliaLogger.i(
        'iOS notification budget: ${pending.length}/'
        '$_iOSSafePendingNotificationLimit pending',
      );
      return available;
    } catch (error, stack) {
      // A failed inspection must not risk exceeding iOS's hard limit.
      TaliaLogger.w('Unable to inspect iOS notification budget', error, stack);
      return 0;
    }
  }

  Future<void> _reserveSlotsForPrayerNotifications(int incomingCount) async {
    if (!Platform.isIOS || incomingCount == 0) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final idsToCancel = notificationIdsToCancelForBudget(
        pendingIds: pending.map((notification) => notification.id),
        incomingCount: incomingCount,
        limit: _iOSSafePendingNotificationLimit,
      );
      for (final id in idsToCancel) {
        await _plugin.cancel(id: id);
      }
      if (idsToCancel.isNotEmpty) {
        TaliaLogger.i(
          'Released ${idsToCancel.length} lower-priority iOS notifications '
          'for prayer reminders',
        );
      }
    } catch (error, stack) {
      TaliaLogger.w(
        'Unable to reserve iOS prayer notification slots',
        error,
        stack,
      );
    }
  }

  // 1. Daily Review Actions & Category
  List<AndroidNotificationAction> get _reviewActions => [
    AndroidNotificationAction(
      'action_review',
      _l10n.notificationActionReviewStart,
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'action_quran',
      _l10n.notificationActionDailyWird,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 2. Streak Protection Actions & Category
  List<AndroidNotificationAction> get _streakActions => [
    AndroidNotificationAction(
      'action_streak',
      _l10n.notificationActionStreakProtect,
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'action_quran',
      _l10n.notificationActionReadWird,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 3. Daily Ayah Actions & Category
  List<AndroidNotificationAction> get _dailyAyahActions => [
    AndroidNotificationAction(
      'action_daily_ayah',
      _l10n.notificationActionReadDailyAyah,
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'action_share_daily_ayah',
      _l10n.notificationActionShareAyah,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 4. Morning Azkar Actions & Category
  List<AndroidNotificationAction> get _morningAzkarActions => [
    AndroidNotificationAction(
      'action_morning_azkar',
      _l10n.notificationActionMorningAzkar,
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'action_quran',
      _l10n.notificationActionDailyWird,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 5. Evening Azkar Actions & Category
  List<AndroidNotificationAction> get _eveningAzkarActions => [
    AndroidNotificationAction(
      'action_evening_azkar',
      _l10n.notificationActionEveningAzkar,
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'action_quran',
      _l10n.notificationActionDailyWird,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 6. Daily Dua Actions & Category
  List<AndroidNotificationAction> get _dailyDuaActions => [
    AndroidNotificationAction(
      'action_daily_dua',
      _l10n.notificationActionDailyDua,
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'action_azkar',
      _l10n.notificationActionAzkar,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 7. Kids Review Actions & Category
  List<AndroidNotificationAction> get _kidsReviewActions => [
    AndroidNotificationAction(
      'action_kids_review',
      _l10n.notificationActionKidsReview,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 8. Friday Surah Al-Kahf Actions
  List<AndroidNotificationAction> get _fridayKahfActions => [
    AndroidNotificationAction(
      'action_read_kahf',
      _l10n.notificationActionReadKahf,
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'action_quran',
      _l10n.notificationActionOpenMushaf,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 9. Tahajjud Actions
  List<AndroidNotificationAction> get _tahajjudActions => [
    AndroidNotificationAction(
      'action_tahajjud',
      _l10n.notificationActionTahajjudDua,
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'action_quran',
      _l10n.notificationActionOpenMushaf,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 10. Khatmah Actions
  List<AndroidNotificationAction> get _khatmahActions => [
    AndroidNotificationAction(
      'action_khatmah',
      _l10n.notificationActionFollowKhatmah,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  // 11. Prayer Times Actions
  List<AndroidNotificationAction> get _prayerActions => [
    AndroidNotificationAction(
      'action_quran',
      _l10n.notificationActionReadQuran,
      showsUserInterface: true,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'action_azkar',
      _l10n.notificationActionPostPrayerAzkar,
      showsUserInterface: true,
      cancelNotification: true,
    ),
  ];

  List<DarwinNotificationCategory> get _darwinCategories => [
    DarwinNotificationCategory(
      'review_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_review',
          _l10n.notificationActionReviewStart,
        ),
        DarwinNotificationAction.plain(
          'action_quran',
          _l10n.notificationActionDailyWird,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'streak_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_streak',
          _l10n.notificationActionStreakProtect,
        ),
        DarwinNotificationAction.plain(
          'action_quran',
          _l10n.notificationActionReadWird,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'daily_ayah_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_daily_ayah',
          _l10n.notificationActionReadDailyAyah,
        ),
        DarwinNotificationAction.plain(
          'action_share_daily_ayah',
          _l10n.notificationActionShareAyah,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'morning_azkar_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_morning_azkar',
          _l10n.notificationActionMorningAzkar,
        ),
        DarwinNotificationAction.plain(
          'action_quran',
          _l10n.notificationActionDailyWird,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'evening_azkar_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_evening_azkar',
          _l10n.notificationActionEveningAzkar,
        ),
        DarwinNotificationAction.plain(
          'action_quran',
          _l10n.notificationActionDailyWird,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'daily_dua_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_daily_dua',
          _l10n.notificationActionDailyDua,
        ),
        DarwinNotificationAction.plain(
          'action_azkar',
          _l10n.notificationActionAzkar,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'kids_review_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_kids_review',
          _l10n.notificationActionKidsReview,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'friday_kahf_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_read_kahf',
          _l10n.notificationActionReadKahf,
        ),
        DarwinNotificationAction.plain(
          'action_quran',
          _l10n.notificationActionOpenMushaf,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'tahajjud_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_tahajjud',
          _l10n.notificationActionTahajjudDua,
        ),
        DarwinNotificationAction.plain(
          'action_quran',
          _l10n.notificationActionOpenMushaf,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'khatmah_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_khatmah',
          _l10n.notificationActionFollowKhatmah,
        ),
      ],
    ),
    DarwinNotificationCategory(
      'prayer_category',
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain(
          'action_quran',
          _l10n.notificationActionReadQuran,
        ),
        DarwinNotificationAction.plain(
          'action_azkar',
          _l10n.notificationActionPostPrayerAzkar,
        ),
      ],
    ),
  ];

  NotificationDetails get _dailyReviewNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_reminders',
          _l10n.notificationChannelRemindersName,
          channelDescription: _l10n.notificationChannelRemindersDescription,
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

  NotificationDetails get _streakNotificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'talia_streak',
      _l10n.notificationChannelStreakName,
      channelDescription: _l10n.notificationChannelStreakDescription,
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

  NotificationDetails get _streakGentleNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_streak_gentle',
          _l10n.notificationChannelStreakGentleName,
          channelDescription: _l10n.notificationChannelStreakGentleDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFFE67E22),
          icon: _notificationIcon,
          playSound: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
          categoryIdentifier: 'streak_gentle_category',
        ),
      );

  NotificationDetails get _smartReminderNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_smart',
          _l10n.notificationChannelSmartName,
          channelDescription: _l10n.notificationChannelSmartDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFF1B6B93),
          icon: _notificationIcon,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'smart_category',
        ),
      );

  NotificationDetails get _dailyAyahNotificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'talia_daily_ayah',
      _l10n.notificationChannelDailyAyahName,
      channelDescription: _l10n.notificationChannelDailyAyahDescription,
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

  NotificationDetails get _morningAzkarNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_morning_azkar',
          _l10n.notificationChannelMorningAzkarName,
          channelDescription: _l10n.notificationChannelMorningAzkarDescription,
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

  NotificationDetails get _eveningAzkarNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_evening_azkar',
          _l10n.notificationChannelEveningAzkarName,
          channelDescription: _l10n.notificationChannelEveningAzkarDescription,
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

  NotificationDetails get _dailyDuaNotificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'talia_daily_dua',
      _l10n.notificationChannelDailyDuaName,
      channelDescription: _l10n.notificationChannelDailyDuaDescription,
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

  NotificationDetails get _kidsReviewNotificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'talia_kids',
      _l10n.notificationChannelKidsName,
      channelDescription: _l10n.notificationChannelKidsDescription,
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

  NotificationDetails get _fridayKahfNotificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'talia_kahf',
      _l10n.notificationChannelKahfName,
      channelDescription: _l10n.notificationChannelKahfDescription,
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

  NotificationDetails get _tahajjudNotificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'talia_tahajjud',
      _l10n.notificationChannelTahajjudName,
      channelDescription: _l10n.notificationChannelTahajjudDescription,
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

  NotificationDetails get _khatmahNotificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'talia_khatmah',
      _l10n.notificationChannelKhatmahName,
      channelDescription: _l10n.notificationChannelKhatmahDescription,
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

  /// Immediate milestone celebration channel (juz/surah/khatmah completion).
  /// No interactive actions — a single tap opens the progress screen.
  NotificationDetails get _milestoneCelebrationNotificationDetails =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'talia_milestones',
          _l10n.notificationChannelMilestonesName,
          channelDescription: _l10n.notificationChannelMilestonesDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF1E824C),
          icon: _notificationIcon,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  NotificationDetails get _prayerNotificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'talia_prayer_times',
      _l10n.notificationChannelPrayerName,
      channelDescription: _l10n.notificationChannelPrayerDescription,
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
    // every daily reminder fires hours off. Retain the last verified device
    // timezone rather than guessing a regional timezone.
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        lastKnownTimezonePreferenceKey,
        localTimezone.identifier,
      );
      return;
    } catch (error, stack) {
      TaliaLogger.w('Device timezone lookup failed', error, stack);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastKnownTimezone = prefs.getString(lastKnownTimezonePreferenceKey);
      if (lastKnownTimezone != null) {
        tz.setLocalLocation(tz.getLocation(lastKnownTimezone));
        TaliaLogger.w('Timezone fallback: using last known device timezone');
        return;
      }
    } catch (error, stack) {
      TaliaLogger.w('Saved timezone fallback failed', error, stack);
    }
    TaliaLogger.w(
      'No valid device timezone is available; keeping the timezone package default',
    );
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
        TaliaLogger.w(
          'Android notification permission request failed',
          error,
          stack,
        );
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
      return false;
    }
  }

  /// Resets the app icon badge count (iOS).
  Future<void> clearBadge() async {
    if (!Platform.isIOS) return;
    try {
      await _badgeChannel.invokeMethod<void>('clearBadge');
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
      androidScheduleMode: await resolveTimeCriticalScheduleMode('streak'),
      payload: '/memorization',
    );
  }

  /// Cancel the streak alert (called when the user opens the app or has completed activity today).
  Future<void> cancelStreakAlert() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _streakAlertId);
  }

  /// Schedules a gentle (default importance, silent) streak nudge one hour
  /// before the urgent streak protection alert.
  Future<void> scheduleStreakGentleNudge({
    required String title,
    required String body,
    required int currentStreak,
    required int hour,
    required int minute,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (currentStreak <= 0) return;

    await _plugin.cancel(id: _streakGentleId);

    await _plugin.zonedSchedule(
      id: _streakGentleId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _streakGentleNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/memorization',
    );
  }

  /// Cancel the gentle streak nudge.
  Future<void> cancelStreakGentleNudge() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _streakGentleId);
  }

  // ─── Smart Reminder ─────────────────────────────────────────────────────────

  /// Schedules a smart daily reminder at the user's most frequent app-open
  /// hour (computed by the scheduler from recorded open hours).
  Future<void> scheduleSmartReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _smartReminderId);

    await _plugin.zonedSchedule(
      id: _smartReminderId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _smartReminderNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/memorization',
    );
  }

  /// Cancel the smart reminder.
  Future<void> cancelSmartReminder() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _smartReminderId);
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
    final availableSlots = await _availableScheduledNotificationSlots();
    final scheduleDays = math.min(_dailyAyahScheduleDays, availableSlots);
    for (var dayOffset = 0; dayOffset < scheduleDays; dayOffset++) {
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
    final availableSlots = await _availableScheduledNotificationSlots();
    final scheduleDays = math.min(_azkarScheduleDays, availableSlots);
    for (var dayOffset = 0; dayOffset < scheduleDays; dayOffset++) {
      final scheduledDate = firstDate.add(Duration(days: dayOffset));
      final text =
          approvedTexts[_azkarIndexForDate(
            scheduledDate,
            approvedTexts.length,
          )];

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
    final availableSlots = await _availableScheduledNotificationSlots();
    final scheduleDays = math.min(_azkarScheduleDays, availableSlots);
    for (var dayOffset = 0; dayOffset < scheduleDays; dayOffset++) {
      final scheduledDate = firstDate.add(Duration(days: dayOffset));
      final text =
          approvedTexts[_azkarIndexForDate(
            scheduledDate,
            approvedTexts.length,
          )];

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

    final availableSlots = await _availableScheduledNotificationSlots();
    final scheduleDays = math.min(_dailyDuaScheduleDays, availableSlots);
    for (var dayOffset = 0; dayOffset < scheduleDays; dayOffset++) {
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
    final scheduleMode = await resolveTimeCriticalScheduleMode('prayer_times');
    final upcomingPrayers = prayers
        .where((prayer) => !prayer.scheduledDate.isBefore(now))
        .take(_prayerTimesMaxCount)
        .toList(growable: false);
    await _reserveSlotsForPrayerNotifications(upcomingPrayers.length);
    final availableSlots = await _availableScheduledNotificationSlots();
    for (final prayer in upcomingPrayers.take(availableSlots)) {
      final tzDate = tz.TZDateTime.from(prayer.scheduledDate, tz.local);
      await _plugin.zonedSchedule(
        id: _prayerTimesBaseId + prayer.idOffset,
        title: prayer.title,
        body: prayer.body,
        scheduledDate: tzDate,
        notificationDetails: _prayerNotificationDetails,
        androidScheduleMode: scheduleMode,
        payload: '/',
      );
    }
    if (availableSlots < upcomingPrayers.length) {
      TaliaLogger.w(
        'iOS notification budget deferred '
        '${upcomingPrayers.length - availableSlots} prayer reminders',
      );
    }
  }

  /// Shows an immediate milestone celebration notification (juz, surah or
  /// khatmah completion). Not scheduled — fired once at the moment the
  /// achievement is unlocked. Failure must never break certificate creation,
  /// so callers wrap this in try/catch (see milestone_notification.dart).
  Future<void> showMilestoneCelebration({
    required String title,
    required String body,
    String payload = '/progress',
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.show(
      id: _milestoneCelebrationId,
      title: title,
      body: body,
      notificationDetails: _milestoneCelebrationNotificationDetails,
      payload: payload,
    );
  }

  /// Cancels the milestone celebration notification (id 1100). Provided for
  /// test/cleanup symmetry with [showMilestoneCelebration].
  Future<void> cancelMilestoneCelebration() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _plugin.cancel(id: _milestoneCelebrationId);
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
  Future<bool> showImmediateTestNotification({
    required String title,
    required String body,
    String type = 'azkar',
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    final azkarCategory = switch (type) {
      'azkar' => 'morning',
      'evening_azkar' => 'evening',
      'dua' => 'duas',
      _ => null,
    };
    var notificationBody = body;
    if (azkarCategory != null) {
      final approvedTexts = await _loadApprovedAzkarTexts(azkarCategory);
      if (approvedTexts.isEmpty) return false;
      notificationBody = approvedTexts.first;
    }
    await requestPermissions();
    if (!await areNotificationsGranted()) return false;

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

    try {
      await _plugin.show(
        id: 9999,
        title: title,
        body: notificationBody,
        notificationDetails: testDetails,
        payload: payload,
      );
      return true;
    } catch (error, stack) {
      TaliaLogger.w('Test notification could not be shown', error, stack);
      return false;
    }
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
      TaliaLogger.w(
        'Failed to load approved azkar texts for category $category',
        error,
        stack,
      );
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
