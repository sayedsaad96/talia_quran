import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
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
  // Load environment variables from .env (excluded from Git via .gitignore)
  await dotenv.load(fileName: '.env');

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

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty) {
    throw StateError('Missing Supabase configuration');
  }

  // Initialize Supabase — credentials loaded from .env (never hardcoded)
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Initialize dependency injection
  await configureDependencies();

  // Initialize notifications with sensible defaults
  final notificationService = TaliaNotificationService.instance;
  await notificationService.initialize();
  await notificationService.requestPermissions();

  final prefs = getIt<SharedPreferences>();

  // M03 FIX: Only schedule default notifications on first launch
  // so we don't accidentally cancel/reschedule them every time the app opens
  final notificationsInitialized =
      prefs.getBool('notifications_initialized') ?? false;
  if (!notificationsInitialized) {
    final reviewEnabled =
        prefs.getBool(TaliaNotificationService.dailyReviewPreferenceKey) ??
        true;
    if (reviewEnabled) {
      await notificationService.scheduleDailyReviewReminder(); // 8:00 PM
    }
    await notificationService.scheduleDailyAyahReminder(); // 7:00 AM
    await notificationService.scheduleMorningAzkarReminder(); // 6:00 AM
    await notificationService.scheduleEveningAzkarReminder(); // 6:00 PM
    await notificationService.scheduleDailyDuaReminder(); // 9:00 AM
    await prefs.setBool('notifications_initialized', true);
  }

  final azkarNotificationsInitialized =
      prefs.getBool('notifications_azkar_initialized') ?? false;
  if (!azkarNotificationsInitialized) {
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

    if (morningAzkarEnabled) {
      await notificationService.scheduleMorningAzkarReminder();
    }
    if (eveningAzkarEnabled) {
      await notificationService.scheduleEveningAzkarReminder();
    }
    if (dailyDuaEnabled) {
      await notificationService.scheduleDailyDuaReminder();
    }
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
