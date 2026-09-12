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
import '../sync/background_sync_scheduler.dart';
import '../theme/theme_cubit.dart';
import '../utils/talia_logger.dart';
import '../../features/quran/data/datasources/bookmark_service.dart';
import '../../features/quran/data/services/quran_warmup_service.dart';
import '../../features/settings/presentation/cubits/profile_cubit.dart';

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
  /// 4. First-launch notification scheduling (non-blocking)
  ///
  /// QCF fonts and Quran page data are warmed up in the background by
  /// [QuranWarmupService] once initialization completes, so the reader opens
  /// any page without the shimmer skeleton.
  ///
  /// Set [background] to true when running inside the Workmanager callback
  /// isolate: all notification setup is skipped because the plugin needs a
  /// foreground Activity and crashes the headless engine without one.
  static Future<void> initialize({
    void Function(String step, double progress)? onProgress,
    bool background = false,
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
      await configureDependencies(background: background);

      if (!background) {
        // Pre-load theme, locale, and profile early so they are immediately available
        // without causing redundant MaterialApp rebuilds during startup.
        getIt<ThemeCubit>().loadTheme();
        getIt<LocaleCubit>().loadLocale();
        getIt<ProfileCubit>().loadProfile();

        // Steps 3 & 4: Notifications — foreground only. The notification
        // plugin needs an Activity context that headless Workmanager engines
        // don't have; calling it there throws NullPointerException, which
        // makes the background task report failure and get retried forever.
        onProgress?.call('جارٍ إعداد التنبيهات...', 0.6);
        await _initNotifications();

        // Non-blocking: Scheduling reminders and pre-warming Quran cache
        // runs in the background so the UI transitions immediately.
        unawaited(_scheduleFirstLaunchNotifications());
        unawaited(getIt<QuranWarmupService>().warmUp());
        unawaited(getIt<BookmarkService>().ensureLoaded());

        // Step 5: Register background tasks non-blocking so splash dismisses immediately.
        // Never run inside a background isolate.
        unawaited(_startBackgroundTasks());
      }

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
      final dailyAyahEnabled =
          prefs.getBool(TaliaNotificationService.dailyAyahPreferenceKey) ??
          true;

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
      await prefs.setBool(
        TaliaNotificationService.dailyAyahPreferenceKey,
        dailyAyahEnabled,
      );

      await prefs.setBool('notifications_initialized', true);
      await prefs.setBool('notifications_azkar_initialized', true);
    }

    // Daily ayahs are date-specific. Refresh on every launch so existing
    // users receive the rolling schedule as well as new users.
    final locale = getIt<LocaleCubit>().state;
    final l10n = lookupAppLocalizations(locale);
    await getIt<NotificationScheduler>().refreshNotifications(l10n);

    final notificationService = getIt<TaliaNotificationService>();
    await notificationService.cancelStreakAlert();
  }

  static Future<void> _startBackgroundTasks() async {
    await getIt<BackgroundSyncScheduler>().initialize();
    // One-time data migration: Hifz → MemorizationPlus V2.
    unawaited(getIt<HifzMigrationService>().runIfNeeded());
  }
}
