import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
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
