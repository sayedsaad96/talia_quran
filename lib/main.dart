import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env (excluded from Git via .gitignore)
  await dotenv.load(fileName: '.env');

  // Prevent Google Fonts from fetching fonts at runtime — all fonts are bundled as assets
  GoogleFonts.config.allowRuntimeFetching = false;

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

  // Initialize Supabase — credentials loaded from .env (never hardcoded)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize dependency injection
  await configureDependencies();

  // Initialize notifications with sensible defaults
  final notificationService = TaliaNotificationService.instance;
  await notificationService.initialize();
  await notificationService.requestPermissions();

  final prefs = getIt<SharedPreferences>();
  final reviewEnabled = prefs.getBool('notifications_daily_review') ?? true;

  if (reviewEnabled) {
    await notificationService.scheduleDailyReviewReminder(); // 8:00 PM
  }
  await notificationService.scheduleDailyAyahReminder();   // 7:00 AM
  await notificationService.cancelStreakAlert();            // Cancel stale alerts on launch

  runApp(const TaliaApp());
}
