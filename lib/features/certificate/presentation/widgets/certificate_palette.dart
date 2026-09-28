import 'package:flutter/material.dart';

/// Fixed palettes for the exported certificate image.
///
/// A certificate is a keepsake that must look identical in every app theme
/// and when shared, so its colors are not theme tokens. Exempt from the
/// design-token guard via the `_palette.dart` suffix. Certificate copy is
/// Arabic-only by product decision.
enum CertificateStyleType {
  classicParchment,
  emeraldRoyal,
  pearlGold;

  String get displayName {
    switch (this) {
      case CertificateStyleType.classicParchment:
        return 'الرق الذهبي';
      case CertificateStyleType.emeraldRoyal:
        return 'الزمرد الملكي';
      case CertificateStyleType.pearlGold:
        return 'اللؤلؤ الفاخر';
    }
  }
}

class CertificateStyleTheme {
  final CertificateStyleType type;
  final List<Color> bgGradient;
  final Color borderColor;
  final Color innerBorderColor;
  final Color primaryText;
  final Color secondaryText;
  final Color accentGold;
  final Color badgeBg;
  final Color badgeText;
  final Color sealBg;
  final Color sealGold;
  final bool isDark;

  const CertificateStyleTheme({
    required this.type,
    required this.bgGradient,
    required this.borderColor,
    required this.innerBorderColor,
    required this.primaryText,
    required this.secondaryText,
    required this.accentGold,
    required this.badgeBg,
    required this.badgeText,
    required this.sealBg,
    required this.sealGold,
    required this.isDark,
  });

  static const CertificateStyleTheme classicParchment = CertificateStyleTheme(
    type: CertificateStyleType.classicParchment,
    bgGradient: [Color(0xFFF9F6ED), Color(0xFFF2ECE0)],
    borderColor: Color(0xFFC09B4E),
    innerBorderColor: Color(0x660D251C),
    primaryText: Color(0xFF0D251C),
    secondaryText: Color(0xCC0D251C),
    accentGold: Color(0xFFC09B4E),
    badgeBg: Color(0xFF0D251C),
    badgeText: Color(0xFFF7F4EA),
    sealBg: Color(0xFFF7F4EA),
    sealGold: Color(0xFFC09B4E),
    isDark: false,
  );

  static const CertificateStyleTheme emeraldRoyal = CertificateStyleTheme(
    type: CertificateStyleType.emeraldRoyal,
    bgGradient: [Color(0xFF041F1A), Color(0xFF0A2B24), Color(0xFF041613)],
    borderColor: Color(0xFFE5C158),
    innerBorderColor: Color(0x66E5C158),
    primaryText: Color(0xFFFAF7F0),
    secondaryText: Color(0xCCD5E0DC),
    accentGold: Color(0xFFE5C158),
    badgeBg: Color(0xFFE5C158),
    badgeText: Color(0xFF041F1A),
    sealBg: Color(0xFF0A2B24),
    sealGold: Color(0xFFE5C158),
    isDark: true,
  );

  static const CertificateStyleTheme pearlGold = CertificateStyleTheme(
    type: CertificateStyleType.pearlGold,
    bgGradient: [Color(0xFFFFFFFF), Color(0xFFFAF7F2)],
    borderColor: Color(0xFFD4AF37),
    innerBorderColor: Color(0x40D4AF37),
    primaryText: Color(0xFF1F2927),
    secondaryText: Color(0xCC5A6663),
    accentGold: Color(0xFFB8860B),
    badgeBg: Color(0xFF1A6B5A),
    badgeText: Color(0xFFFFFFFF),
    sealBg: Color(0xFFFFFFFF),
    sealGold: Color(0xFFD4AF37),
    isDark: false,
  );

  static CertificateStyleTheme get(CertificateStyleType type) {
    switch (type) {
      case CertificateStyleType.classicParchment:
        return classicParchment;
      case CertificateStyleType.emeraldRoyal:
        return emeraldRoyal;
      case CertificateStyleType.pearlGold:
        return pearlGold;
    }
  }
}

/// Chrome of the certificate preview page (dark gallery around the image).
abstract final class CertificatePagePalette {
  static const background = Color(0xFF0D131A);
  static const gold = Color(0xFFE5C158);
  static const goldMuted = Color(0xFFC9A84C);
}
