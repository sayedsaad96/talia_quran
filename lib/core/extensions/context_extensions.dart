import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

extension BuildContextX on BuildContext {
  // ─── Theme ───────────────────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ─── Localization ─────────────────────────────────────────────────────────────
  AppLocalizations get l10n => AppLocalizations.of(this);
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  // ─── Sizing ──────────────────────────────────────────────────────────────────
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  double get topPadding => MediaQuery.paddingOf(this).top;
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;
  bool get isSmallScreen => screenWidth < 360;
  bool get isWideScreen => screenWidth >= 600;
  bool get isTablet => screenWidth >= 720;

  // ─── Navigation ──────────────────────────────────────────────────────────────
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Shows a SnackBar that is guaranteed to auto-hide after [duration]
  /// (default 4 seconds).
  ///
  /// In Flutter, SnackBars with an [action] default to `persist = true`,
  /// which stops Flutter from auto-dismissing them. This wrapper enforces
  /// `persist: false`, clears any existing SnackBar, and provides a guaranteed
  /// fallback timer so the SnackBar never stays permanently on screen.
  void showAutoDismissSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
      persist: false,
    );
    final controller = messenger.showSnackBar(snackBar);
    Timer(duration + const Duration(milliseconds: 200), () {
      try {
        controller.close();
      } catch (_) {}
    });
  }

  String localizeLevelName(String name) {
    switch (name) {
      case 'مبتدئ':
        return l10n.levelBeginner;
      case 'طالب':
        return l10n.levelStudent;
      case 'حافظ':
        return l10n.levelHafez;
      case 'شيخ':
        return l10n.levelSheikh;
      case 'إمام':
        return l10n.levelImam;
      default:
        return name;
    }
  }
}
