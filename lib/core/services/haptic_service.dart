import 'package:flutter/services.dart';

/// Haptic feedback service — static methods for easy use from anywhere
class HapticService {
  const HapticService._();

  /// Light impact — on successful ayah memorization or any successful action
  static Future<void> success() => HapticFeedback.lightImpact();

  /// Heavy impact — on error or alert
  static Future<void> error() => HapticFeedback.heavyImpact();

  /// Selection click — on toggling an option or navigation
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Multiple vibrations — on completing a page or juz
  static Future<void> celebration() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }
}
