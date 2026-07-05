import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/services/hifz_migration_service.dart';
import 'core/services/notification_scheduler.dart';
import 'core/services/notification_service.dart';
import 'core/utils/talia_logger.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // M01 FIX: Global error handler — show friendly UI in production instead of red screen
      FlutterError.onError = (details) {
        TaliaLogger.e(
          'Flutter framework error',
          details.exception,
          details.stack,
        );
        if (kDebugMode) {
          FlutterError.presentError(details);
        }
      };

      // M01 FIX: Friendly error widget for production
      if (!kDebugMode) {
        ErrorWidget.builder = (details) => const Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'حدث خطأ غير متوقع.\nيرجى إعادة تشغيل التطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        );
      }

      try {
        await _bootstrapAndRun();
      } catch (error, stack) {
        TaliaLogger.e('App bootstrap failed', error, stack);
        runApp(const _StartupFailureApp());
      }
    },
    (error, stack) {
      TaliaLogger.e('Uncaught async error', error, stack);
    },
  );
}

Future<void> _bootstrapAndRun() async {
  // Prevent Google Fonts from fetching fonts at runtime — all fonts are bundled as assets
  GoogleFonts.config.allowRuntimeFetching = false;

  await QcfFontLoader.setupFontsAtStartup(onProgress: (_) {});

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  const supabaseConfig = SupabaseConfig.fromDartDefine;

  // Debug-only: log config status without printing secret values.
  assert(() {
    TaliaLogger.d(
      'BEFORE SUPABASE INIT | '
      'configured=${supabaseConfig.isConfigured} | '
      'url=${supabaseConfig.url} | '
      'keyLength=${supabaseConfig.anonKey.length}',
    );
    return true;
  }());

  // OFFLINE-FIRST: Supabase config is supplied through --dart-define.
  // If absent, continue in offline mode; local Quran, Hifz, Azkar, progress,
  // and memorization features must remain reachable.
  if (supabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: supabaseConfig.url.trim(),
      publishableKey: supabaseConfig.anonKey.trim(),
    );

    TaliaLogger.d('SUPABASE INIT SUCCESS');
  } else {
    TaliaLogger.w('SUPABASE INIT SKIPPED');
  }
  // If Supabase is not configured, auth/cloud features return friendly offline
  // errors while local-first features continue to work.

  // Initialize dependency injection
  await configureDependencies();

  // Initialize notifications with sensible defaults
  final notificationService = getIt<TaliaNotificationService>();
  await notificationService.initialize();
  // M05 FIX: Do not await requestPermissions() before runApp.
  // Awaiting this before runApp() on Android 13+ blocks the main isolate
  // while the OS permission dialog is active. If the dialog is hidden behind
  // the splash screen, the app will appear to hang infinitely.
  unawaited(
    notificationService.requestPermissions(),
  ); // intentionally not awaited

  // One-time data migration: Hifz → MemorizationPlus V2.
  // Runs in the background after app starts — no startup delay.
  unawaited(
    getIt<HifzMigrationService>().runIfNeeded(),
  );

  final prefs = getIt<SharedPreferences>();

  // M03 FIX: Only schedule default notifications on first launch.
  // Both flags are merged to prevent the old double-scheduling bug where
  // morning/evening azkar and daily dua were scheduled in both blocks.
  final notificationsInitialized =
      prefs.getBool('notifications_initialized') ?? false;
  if (!notificationsInitialized) {
    // Read (or default) all per-type preferences before first scheduling
    final morningAzkarEnabled =
        prefs.getBool(TaliaNotificationService.morningAzkarPreferenceKey) ??
        true;
    final eveningAzkarEnabled =
        prefs.getBool(TaliaNotificationService.eveningAzkarPreferenceKey) ??
        true;
    final dailyDuaEnabled =
        prefs.getBool(TaliaNotificationService.dailyDuaPreferenceKey) ?? true;

    // Persist defaults so Settings page reads them correctly
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

    // Schedule all notifications based on preferences
    final locale = getIt<LocaleCubit>().state;
    final l10n = lookupAppLocalizations(locale);
    final scheduler = getIt<NotificationScheduler>();
    await scheduler.refreshNotifications(l10n);

    await prefs.setBool('notifications_initialized', true);
    // Mark the old azkar flag too so existing installs don't re-run the old block
    await prefs.setBool('notifications_azkar_initialized', true);
  }

  await notificationService
      .cancelStreakAlert(); // Cancel stale alerts on launch

  runApp(const TaliaApp());
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'تعذر تشغيل تالية حالياً.\nتأكد من إعدادات التطبيق ثم أعد المحاولة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
