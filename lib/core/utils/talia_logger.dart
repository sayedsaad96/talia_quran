import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

typedef TaliaErrorReporter =
    FutureOr<void> Function(
      String message,
      Object? error,
      StackTrace? stackTrace,
    );

/// Centralized logger for Talia Quran.
///
/// In production, this can be extended to send logs to a service like Sentry or Crashlytics.
class TaliaLogger {
  static TaliaErrorReporter? _errorReporter;

  static void setErrorReporter(TaliaErrorReporter? reporter) {
    _errorReporter = reporter;
  }

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
    // Always log errors, even in release builds.
    dev.log(
      message,
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );

    final reporter = _errorReporter;
    if (reporter == null) return;

    unawaited(
      Future<void>.sync(() => reporter(message, error, stackTrace)).catchError((
        Object reportingError,
        StackTrace reportingStack,
      ) {
        if (kDebugMode) {
          dev.log(
            'Error reporter failed',
            name: 'ERROR',
            error: reportingError,
            stackTrace: reportingStack,
            time: DateTime.now(),
          );
        }
      }),
    );
  }
}
