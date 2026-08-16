import 'package:flutter/material.dart';

import 'social_share_model.dart';

enum SocialShareThemeType {
  emeraldDark,
  midnightGold,
  dawnLight,
  tealTwilight,
  parchmentGold;

  String get nameAr {
    switch (this) {
      case SocialShareThemeType.emeraldDark:
        return 'الزمرد الملكي';
      case SocialShareThemeType.midnightGold:
        return 'الليل والذهب';
      case SocialShareThemeType.dawnLight:
        return 'الفجر الهادئ';
      case SocialShareThemeType.tealTwilight:
        return 'شفق الفيروز';
      case SocialShareThemeType.parchmentGold:
        return 'الرق الدافئ';
    }
  }

  String get nameEn {
    switch (this) {
      case SocialShareThemeType.emeraldDark:
        return 'Royal Emerald';
      case SocialShareThemeType.midnightGold:
        return 'Midnight Gold';
      case SocialShareThemeType.dawnLight:
        return 'Quiet Dawn';
      case SocialShareThemeType.tealTwilight:
        return 'Turquoise Dusk';
      case SocialShareThemeType.parchmentGold:
        return 'Warm Parchment';
    }
  }

  /// Content-driven default: each share type opens on a style that fits its
  /// visual language (typography-first for Quran, celebratory for
  /// achievements, calm for dua) and its audience (warmer for kids).  The
  /// user can still override the choice in the sheet.
  static SocialShareThemeType defaultFor(
    SocialShareCategory category, {
    SocialShareAudience audience = SocialShareAudience.adult,
  }) {
    final kids = audience == SocialShareAudience.kids;
    switch (category) {
      case SocialShareCategory.quranAyah:
        return SocialShareThemeType.parchmentGold;
      case SocialShareCategory.dua:
      case SocialShareCategory.azkar:
        return SocialShareThemeType.dawnLight;
      case SocialShareCategory.achievement:
      case SocialShareCategory.memorization:
        return kids
            ? SocialShareThemeType.parchmentGold
            : SocialShareThemeType.emeraldDark;
      case SocialShareCategory.streak:
        return kids
            ? SocialShareThemeType.dawnLight
            : SocialShareThemeType.midnightGold;
      case SocialShareCategory.progress:
        return kids
            ? SocialShareThemeType.parchmentGold
            : SocialShareThemeType.dawnLight;
      case SocialShareCategory.certificate:
        return SocialShareThemeType.parchmentGold;
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

  /// On-brand teal/turquoise palette replacing the former off-brand purple
  /// gradient: deep royal teal drifting into luminous turquoise with warm
  /// gold accents, staying inside the Talia visual identity.
  static const SocialShareTheme tealTwilight = SocialShareTheme(
    type: SocialShareThemeType.tealTwilight,
    backgroundGradient: [Color(0xFF052E2B), Color(0xFF0F5550), Color(0xFF0A3B37)],
    cardBackground: Color(0xFF0E4640),
    borderColor: Color(0xFF7FCBBB),
    accentColor: Color(0xFF7EE0C9),
    textPrimary: Color(0xFFFAF7F0),
    textSecondary: Color(0xFFBFD9D2),
    badgeBackground: Color(0x2E7EE0C9),
    badgeTextColor: Color(0xFFBFF2E5),
    patternColor: Color(0x14FFFFFF),
    glowColor: Color(0x332BD4C0),
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
      case SocialShareThemeType.tealTwilight:
        return tealTwilight;
      case SocialShareThemeType.parchmentGold:
        return parchmentGold;
    }
  }
}
