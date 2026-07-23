import 'package:flutter/material.dart';

enum SocialShareThemeType {
  emeraldDark,
  midnightGold,
  dawnLight,
  royalGradient;

  String get displayName {
    switch (this) {
      case SocialShareThemeType.emeraldDark:
        return 'الزمرد الملكي';
      case SocialShareThemeType.midnightGold:
        return 'الليل والذهب';
      case SocialShareThemeType.dawnLight:
        return 'الفجر الهادئ';
      case SocialShareThemeType.royalGradient:
        return 'الأرجوان الملكي';
    }
  }
}

class SocialShareTheme {
  final SocialShareThemeType type;
  final List<Color> backgroundGradient;
  final Color cardBackground;
  final Color borderColor;
  final Color accentColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color badgeBackground;
  final Color badgeTextColor;
  final Color patternColor;
  final bool isDark;

  const SocialShareTheme({
    required this.type,
    required this.backgroundGradient,
    required this.cardBackground,
    required this.borderColor,
    required this.accentColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.badgeBackground,
    required this.badgeTextColor,
    required this.patternColor,
    required this.isDark,
  });

  static const SocialShareTheme emeraldDark = SocialShareTheme(
    type: SocialShareThemeType.emeraldDark,
    backgroundGradient: [Color(0xFF041F1A), Color(0xFF0D3B33), Color(0xFF041915)],
    cardBackground: Color(0xFF0A2B24),
    borderColor: Color(0xD6D4AF37), // Metallic Gold border
    accentColor: Color(0xFFE5C158),
    textPrimary: Color(0xFFFAF7F0),
    textSecondary: Color(0xFFC7D3CD),
    badgeBackground: Color(0x33E5C158),
    badgeTextColor: Color(0xFFF3E2A9),
    patternColor: Color(0x1AEAEEEC),
    isDark: true,
  );

  static const SocialShareTheme midnightGold = SocialShareTheme(
    type: SocialShareThemeType.midnightGold,
    backgroundGradient: [Color(0xFF0B101D), Color(0xFF141C30), Color(0xFF080C16)],
    cardBackground: Color(0xFF121B2E),
    borderColor: Color(0xFFE5C158),
    accentColor: Color(0xFFF8E089),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0C0DA),
    badgeBackground: Color(0x33F8E089),
    badgeTextColor: Color(0xFFFDE8A5),
    patternColor: Color(0x18FFFFFF),
    isDark: true,
  );

  static const SocialShareTheme dawnLight = SocialShareTheme(
    type: SocialShareThemeType.dawnLight,
    backgroundGradient: [Color(0xFFFCFAF5), Color(0xFFF4ECE1), Color(0xFFFAF6EE)],
    cardBackground: Color(0xFFFFFFFF),
    borderColor: Color(0xFF0D5C53),
    accentColor: Color(0xFF0D5C53),
    textPrimary: Color(0xFF1F2927),
    textSecondary: Color(0xFF5A6663),
    badgeBackground: Color(0x1A0D5C53),
    badgeTextColor: Color(0xFF0D5C53),
    patternColor: Color(0x0C0D5C53),
    isDark: false,
  );

  static const SocialShareTheme royalGradient = SocialShareTheme(
    type: SocialShareThemeType.royalGradient,
    backgroundGradient: [Color(0xFF1F0E3D), Color(0xFF3B1B66), Color(0xFF14082B)],
    cardBackground: Color(0xFF281447),
    borderColor: Color(0xFFFFD700),
    accentColor: Color(0xFFFFD700),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD6C8EF),
    badgeBackground: Color(0x33FFD700),
    badgeTextColor: Color(0xFFFFF3B0),
    patternColor: Color(0x20FFFFFF),
    isDark: true,
  );

  static SocialShareTheme get(SocialShareThemeType type) {
    switch (type) {
      case SocialShareThemeType.emeraldDark:
        return emeraldDark;
      case SocialShareThemeType.midnightGold:
        return midnightGold;
      case SocialShareThemeType.dawnLight:
        return dawnLight;
      case SocialShareThemeType.royalGradient:
        return royalGradient;
    }
  }
}
