import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize dependency injection
  await configureDependencies();

  // Initialize notifications with sensible defaults
  final notificationService = TaliaNotificationService.instance;
  await notificationService.initialize();
  await notificationService.scheduleDailyReviewReminder(); // 8:00 PM
  await notificationService.scheduleDailyAyahReminder();   // 7:00 AM
  await notificationService.cancelStreakAlert();            // Cancel stale alerts on launch

  runApp(const TaliaApp());
}
