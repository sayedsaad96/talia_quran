import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Centralized logger for Talia Quran.
///
/// In production, this can be extended to send logs to a service like Sentry or Crashlytics.
class TaliaLogger {
  static void d(String message) {
    if (kDebugMode) {
      dev.log(message, name: 'DEBUG', time: DateTime.now());
    }
  }

  static void i(String message) {
    if (kDebugMode) {
      dev.log(message, name: 'INFO', time: DateTime.now());
    }
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      dev.log(
        message,
        name: 'WARN',
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      dev.log(
        message,
        name: 'ERROR',
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    }
    
    // TODO: Send to remote crash reporting service (e.g. Sentry/Firebase)
    // This part should run in production for critical errors.
  }
}
