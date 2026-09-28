import 'package:flutter/widgets.dart';

import 'social_share_model.dart';

/// Looks offered in the share sheet. `auto` follows the shared content;
/// `night` and `day` force one look for every category.
enum SocialShareMood { auto, night, day }

enum SharePaletteId {
  mushafLight,
  suhoor,
  dusk,
  sunrise,
  forenoon,
  kidsMorning,
  night,
  day,
}

// Brand colours from the Talia logo and AppColors. Exported images never
// follow the device theme, so cards use these literals, not app tokens.
const _ink = Color(0xFF021210);
const _emeraldDeep = Color(0xFF042F2E);
const _emerald = Color(0xFF0D5C53);
const _emeraldLight = Color(0xFF148275);
const _mushafGlow = Color(0xFFFFCE6E);
const _ivoryText = Color(0xFFFFF8EC);
const _mistText = Color(0xFFD9E6E1);
const _gold = Color(0xFFF5C45A);
const _paper = Color(0xFFF0EDE6);
const _glass = Color(0xB3021210);
const _glassBorder = Color(0x73F5C45A);
const _archGold = Color(0x8CF5C45A);
const _whiteWatermark = Color(0x12FFFFFF);

/// Fixed colours for one exported card look.
@immutable
class SharePalette {
  const SharePalette({
    required this.id,
    required this.skyTop,
    required this.skyMid,
    required this.skyBase,
    required this.glow,
    required this.glowStrength,
    required this.glowRadius,
    required this.textPrimary,
    required this.textSecondary,
    required this.textAccent,
    required this.eyebrow,
    required this.watermark,
    required this.archLine,
    required this.signatureSurface,
    required this.signatureBorder,
    required this.signatureText,
    required this.wordmark,
    required this.qrForeground,
    required this.qrBackground,
  });

  /// Emerald night sky lit by the golden mushaf light from below.
  const SharePalette._dark({
    required this.id,
    required this.skyTop,
    required this.skyMid,
    required this.skyBase,
    this.glow = _mushafGlow,
    this.glowStrength = 0.92,
    this.glowRadius = 0.85,
    this.textPrimary = _ivoryText,
    this.textSecondary = _mistText,
    this.textAccent = _gold,
    this.eyebrow = _gold,
  }) : watermark = _whiteWatermark,
       archLine = _archGold,
       signatureSurface = _glass,
       signatureBorder = _glassBorder,
       signatureText = _paper,
       wordmark = _gold,
       qrForeground = _emeraldDeep,
       qrBackground = _paper;

  final SharePaletteId id;
  final Color skyTop;
  final Color skyMid;
  final Color skyBase;
  final Color glow;

  /// Opacity of the mushaf light at its centre (bottom of the card).
  final double glowStrength;

  /// Radial reach of the light, as a fraction of the card's shortest side.
  final double glowRadius;
  final Color textPrimary;
  final Color textSecondary;
  final Color textAccent;
  final Color eyebrow;
  final Color watermark;
  final Color archLine;
  final Color signatureSurface;
  final Color signatureBorder;
  final Color signatureText;
  final Color wordmark;
  final Color qrForeground;
  final Color qrBackground;
}

abstract final class SharePalettes {
  static const mushafLight = SharePalette._dark(
    id: SharePaletteId.mushafLight,
    skyTop: _ink,
    skyMid: _emeraldDeep,
    skyBase: _emerald,
  );

  /// Pre-dawn indigo hint — the time of supplication.
  static const suhoor = SharePalette._dark(
    id: SharePaletteId.suhoor,
    skyTop: Color(0xFF0B1530),
    skyMid: Color(0xFF062C35),
    skyBase: _emerald,
    glowStrength: 0.75,
  );

  /// Evening teal-blue for remembrance.
  static const dusk = SharePalette._dark(
    id: SharePaletteId.dusk,
    skyTop: Color(0xFF06202E),
    skyMid: Color(0xFF053338),
    skyBase: _emerald,
    glowStrength: 0.75,
  );

  /// Full sunrise for achievements, certificates and khatmah.
  static const sunrise = SharePalette._dark(
    id: SharePaletteId.sunrise,
    skyTop: _ink,
    skyMid: Color(0xFF0A3A33),
    skyBase: _emeraldLight,
    glowStrength: 1,
    glowRadius: 1.15,
  );

  static const forenoon = SharePalette._dark(
    id: SharePaletteId.forenoon,
    skyTop: _ink,
    skyMid: _emeraldDeep,
    skyBase: _emeraldLight,
  );

  static const kidsMorning = SharePalette._dark(
    id: SharePaletteId.kidsMorning,
    skyTop: _emerald,
    skyMid: _emeraldLight,
    skyBase: Color(0xFF1FA08E),
    glow: Color(0xFFFFD978),
    glowStrength: 1,
    glowRadius: 1.1,
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFFFFFF),
    textAccent: Color(0xFFFFE9A8),
    eyebrow: Color(0xFFFFFFFF),
  );

  static const night = SharePalette._dark(
    id: SharePaletteId.night,
    skyTop: _ink,
    skyMid: _emeraldDeep,
    skyBase: _emerald,
    glowStrength: 0.55,
  );

  static const day = SharePalette(
    id: SharePaletteId.day,
    skyTop: Color(0xFFFDFCF8),
    skyMid: Color(0xFFFDFCF8),
    skyBase: Color(0xFFFBF3E2),
    glow: Color(0xFFF59E0B),
    glowStrength: 0.28,
    glowRadius: 0.95,
    textPrimary: Color(0xFF1A1209),
    textSecondary: Color(0xFF6B5E4E),
    textAccent: Color(0xFF8A6414),
    eyebrow: _emerald,
    watermark: Color(0x128A5A1A),
    archLine: Color(0x99B8862A),
    signatureSurface: _emeraldDeep,
    signatureBorder: _glassBorder,
    signatureText: _paper,
    wordmark: _gold,
    qrForeground: _emeraldDeep,
    qrBackground: _paper,
  );

  static const List<SharePalette> all = [
    mushafLight,
    suhoor,
    dusk,
    sunrise,
    forenoon,
    kidsMorning,
    night,
    day,
  ];

  static SharePalette resolve(SocialShareData data, SocialShareMood mood) {
    return switch (mood) {
      SocialShareMood.night => night,
      SocialShareMood.day => day,
      SocialShareMood.auto =>
        data.audience == SocialShareAudience.kids
            ? kidsMorning
            : forCategory(data.category),
    };
  }

  static SharePalette forCategory(SocialShareCategory category) {
    return switch (category) {
      SocialShareCategory.quranAyah => mushafLight,
      SocialShareCategory.dua => suhoor,
      SocialShareCategory.azkar => dusk,
      SocialShareCategory.achievement ||
      SocialShareCategory.certificate ||
      SocialShareCategory.khatmah => sunrise,
      SocialShareCategory.memorization ||
      SocialShareCategory.progress ||
      SocialShareCategory.streak => forenoon,
    };
  }
}
