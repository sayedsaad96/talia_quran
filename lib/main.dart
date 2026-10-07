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

      // Generic Talia icon glyphs are based on Lucide (ISC); list it with
      // the other open-source licenses.
      LicenseRegistry.addLicense(() async* {
        final text = await rootBundle.loadString(
          'assets/fonts/TaliaIcons/LICENSE-lucide.txt',
        );
        yield LicenseEntryWithLineBreaks(const ['Lucide icons'], text);
      });

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

      // Catch errors from platform channels, timers and microtasks that
      // runZonedGuarded no longer receives since Flutter 3.1.
      PlatformDispatcher.instance.onError = (error, stack) {
        TaliaLogger.e('Uncaught platform error', error, stack);
        return true;
      };

      // M01 FIX: Friendly error widget for production
      if (!kDebugMode) {
        ErrorWidget.builder = (details) => const Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              // Localizations may be unavailable here: show both languages.
              child: Text(
                'حدث خطأ غير متوقع.\nيرجى إعادة تشغيل التطبيق.\n\n'
                'Something went wrong.\nPlease restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        );
      }

      await _bootstrapWithRetry();
    },
    (error, stack) {
      TaliaLogger.e('Uncaught async error', error, stack);
    },
  );
}

Future<void> _bootstrapWithRetry() async {
  try {
    await _bootstrapAndRun();
  } catch (error, stack) {
    TaliaLogger.e('App bootstrap failed', error, stack);
    runApp(const _StartupFailureApp(onRetry: _bootstrapWithRetry));
  }
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

/// Shown when bootstrap fails, before localizations exist: both languages,
/// and a retry that runs the bootstrap again.
class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'تعذر تشغيل تالية حالياً.\nأعد المحاولة.\n\n'
                    'Talia could not start.\nPlease try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('إعادة المحاولة / Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
