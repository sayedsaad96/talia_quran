import 'package:flutter/material.dart';

enum SocialShareThemeType {
  emeraldDark,
  midnightGold,
  dawnLight,
  royalGradient,
  parchmentGold;

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
      case SocialShareThemeType.parchmentGold:
        return 'الرق الدافئ';
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
  final Color glowColor;
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
    required this.glowColor,
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
    glowColor: Color(0x331A6B5A),
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
    glowColor: Color(0x33D4A017),
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
    glowColor: Color(0x200D5C53),
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
    glowColor: Color(0x33FFD700),
    isDark: true,
  );

  static const SocialShareTheme parchmentGold = SocialShareTheme(
    type: SocialShareThemeType.parchmentGold,
    backgroundGradient: [Color(0xFFF5EDD6), Color(0xFFEDE4C8), Color(0xFFE5DAAF)],
    cardBackground: Color(0xFFFAF5E8),
    borderColor: Color(0xFFC8A97A),
    accentColor: Color(0xFF8B6914),
    textPrimary: Color(0xFF1C2B2F),
    textSecondary: Color(0xFF5C6B6F),
    badgeBackground: Color(0x26C8A97A),
    badgeTextColor: Color(0xFF7A5C10),
    patternColor: Color(0x1AC8A97A),
    glowColor: Color(0x33C8A97A),
    isDark: false,
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
      case SocialShareThemeType.parchmentGold:
        return parchmentGold;
    }
  }
}
