import 'package:flutter/material.dart';

/// Talia Typography System
/// Arabic (Display): Amiri
/// Arabic (Body): Noto Naskh Arabic
abstract class AppTypography {
  // ─── Display Fonts (Amiri) ──────────────────────────────────────────────────
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static TextStyle get displayMedium => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static TextStyle get displaySmall => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
  );

  // ─── Body Fonts (Noto Naskh Arabic) ─────────────────────────────────────────
  static TextStyle get headlineLarge => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle get headlineMedium => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get headlineSmall => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static TextStyle get titleLarge => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static TextStyle get titleSmall => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static TextStyle get labelLarge => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static TextStyle get labelMedium => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.3,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontFamily: 'Noto_Naskh_Arabic',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // ─── Arabic Quran Fonts ──────────────────────────────────────────────────────
  /// Used for Quranic text rendering — Amiri has authentic Quranic styling
  static TextStyle get quranLarge => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 2.2,
    letterSpacing: 0,
  );

  static TextStyle get quranMedium => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 2.2,
    letterSpacing: 0,
  );

  static TextStyle get quranSmall => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 2.0,
    letterSpacing: 0,
  );

  /// Used for Surah names and headings
  static TextStyle get surahTitle => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: 0,
  );

  /// Used for Azkar text
  static TextStyle get azkarText => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 2.0,
    letterSpacing: 0,
  );

  /// Optimized for continuous Quranic text in the Mus'haf reader.
  /// Uses 2.4x line height for comfortable reading of long passages.
  static TextStyle get quranVerse => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 2.4,
    letterSpacing: 0,
    wordSpacing: 2.0,
  );

  /// Used for Surah name banners inside the Quran reader pages.
  static TextStyle get quranHeader => const TextStyle(
    fontFamily: 'Amiri',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.6,
    letterSpacing: 0.5,
  );

  // ─── TextTheme builder ───────────────────────────────────────────────────────
  static TextTheme buildTextTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: primaryText),
      displayMedium: displayMedium.copyWith(color: primaryText),
      displaySmall: displaySmall.copyWith(color: primaryText),
      headlineLarge: headlineLarge.copyWith(color: primaryText),
      headlineMedium: headlineMedium.copyWith(color: primaryText),
      headlineSmall: headlineSmall.copyWith(color: primaryText),
      titleLarge: titleLarge.copyWith(color: primaryText),
      titleMedium: titleMedium.copyWith(color: primaryText),
      titleSmall: titleSmall.copyWith(color: secondaryText),
      bodyLarge: bodyLarge.copyWith(color: primaryText),
      bodyMedium: bodyMedium.copyWith(color: primaryText),
      bodySmall: bodySmall.copyWith(color: secondaryText),
      labelLarge: labelLarge.copyWith(color: primaryText),
      labelMedium: labelMedium.copyWith(color: secondaryText),
      labelSmall: labelSmall.copyWith(color: secondaryText),
    );
  }

  const AppTypography._();
}
