import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../di/injection.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_cubit.dart';
import '../services/hifz_migration_service.dart';
import '../services/notification_scheduler.dart';
import '../services/notification_service.dart';
import '../utils/talia_logger.dart';

/// Handles heavy app initialization that was previously blocking `runApp()`.
///
/// Called from [SplashPage] so the UI can display a progress indicator
/// while initialization proceeds.
class AppInitializer {
  AppInitializer._();

  static bool _initialized = false;

  /// Whether initialization has already completed.
  static bool get isInitialized => _initialized;

  @visibleForTesting
  static void resetForTesting({bool initialized = false}) {
    _initialized = initialized;
  }

  /// Runs all heavy initialization steps, reporting progress via [onProgress].
  ///
  /// Steps:
  /// 1. Supabase initialization
  /// 2. Dependency injection (Isar, SharedPreferences, services, cubits)
  /// 3. Notification plugin initialization
  /// 4. First-launch notification scheduling
  ///
  /// QCF fonts are NOT loaded here — they use lazy loading when the Quran
  /// reader opens.
  static Future<void> initialize({
    void Function(String step, double progress)? onProgress,
  }) async {
    if (_initialized) return;

    try {
      // Step 1: Supabase
      onProgress?.call('جارٍ الاتصال...', 0.1);
      await _initSupabase();

      // Step 2: Dependency Injection (heaviest step — Isar, migrations, etc.)
      onProgress?.call('جارٍ تجهيز البيانات...', 0.3);
      if (getIt.isRegistered<SharedPreferences>()) {
        await getIt.reset();
      }
      await configureDependencies();

      // Step 3: Notifications
      onProgress?.call('جارٍ إعداد التنبيهات...', 0.6);
      await _initNotifications();

      // Step 4: First-launch notification scheduling
      onProgress?.call('جارٍ ضبط المواعيد...', 0.8);
      await _scheduleFirstLaunchNotifications();

      // Step 5: Background tasks (fire-and-forget)
      _startBackgroundTasks();

      onProgress?.call('جاهز!', 1.0);
      _initialized = true;
    } catch (error, stack) {
      TaliaLogger.e('AppInitializer failed', error, stack);
      rethrow;
    }
  }

  static Future<void> _initSupabase() async {
    const supabaseConfig = SupabaseConfig.fromDartDefine;

    assert(() {
      TaliaLogger.d(
        'BEFORE SUPABASE INIT | configured=${supabaseConfig.isConfigured}',
      );
      return true;
    }());

    if (!supabaseConfig.isConfigured) {
      TaliaLogger.w('SUPABASE INIT SKIPPED');
      return;
    }
    if (_isSupabaseReady()) return;
    await Supabase.initialize(
      url: supabaseConfig.url.trim(),
      publishableKey: supabaseConfig.anonKey.trim(),
    );
    TaliaLogger.d('SUPABASE INIT SUCCESS');
  }

  static bool _isSupabaseReady() {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _initNotifications() async {
    final notificationService = getIt<TaliaNotificationService>();
    await notificationService.initialize();
    // M05 FIX: Do not await requestPermissions().
    // Awaiting this on Android 13+ blocks the main isolate while the OS
    // permission dialog is active.
    unawaited(notificationService.requestPermissions());
  }

  static Future<void> _scheduleFirstLaunchNotifications() async {
    final prefs = getIt<SharedPreferences>();

    // M03 FIX: Only schedule default notifications on first launch.
    final notificationsInitialized =
        prefs.getBool('notifications_initialized') ?? false;
    if (!notificationsInitialized) {
      final morningAzkarEnabled =
          prefs.getBool(TaliaNotificationService.morningAzkarPreferenceKey) ??
              true;
      final eveningAzkarEnabled =
          prefs.getBool(TaliaNotificationService.eveningAzkarPreferenceKey) ??
              true;
      final dailyDuaEnabled =
          prefs.getBool(TaliaNotificationService.dailyDuaPreferenceKey) ?? true;

      await prefs.setBool(
        TaliaNotificationService.morningAzkarPreferenceKey,
        morningAzkarEnabled,
      );
      await prefs.setBool(
        TaliaNotificationService.eveningAzkarPreferenceKey,
        eveningAzkarEnabled,
      );
      await prefs.setBool(
        TaliaNotificationService.dailyDuaPreferenceKey,
        dailyDuaEnabled,
      );

      final locale = getIt<LocaleCubit>().state;
      final l10n = lookupAppLocalizations(locale);
      final scheduler = getIt<NotificationScheduler>();
      await scheduler.refreshNotifications(l10n);

      await prefs.setBool('notifications_initialized', true);
      await prefs.setBool('notifications_azkar_initialized', true);
    }

    final notificationService = getIt<TaliaNotificationService>();
    await notificationService.cancelStreakAlert();
  }

  static void _startBackgroundTasks() {
    // One-time data migration: Hifz → MemorizationPlus V2.
    unawaited(getIt<HifzMigrationService>().runIfNeeded());
  }
}
