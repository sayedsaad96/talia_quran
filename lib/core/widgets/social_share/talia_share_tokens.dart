import 'package:flutter/material.dart';
import 'social_share_model.dart';

/// Responsive Dimensions & Aspect Ratios
abstract class TaliaShareDimensions {
  /// Standard export canvas width.  Matches the fixed 360-logical export
  /// canvas so previews and exports lay out identically.
  static const double baseWidth = 360.0;

  // Aspect ratios
  static const double portraitRatio = 0.8; // 4:5 -> 1080x1350
  static const double squareRatio = 1.0; // 1:1 -> 1080x1080
  static const double storyRatio = 0.5625; // 9:16 -> 1080x1920

  static double aspectRatioFor(SocialShareFormat format) {
    switch (format) {
      case SocialShareFormat.square:
        return squareRatio;
      case SocialShareFormat.story:
        return storyRatio;
      case SocialShareFormat.portrait:
        return portraitRatio;
    }
  }
}

/// Layout numbers for the Dawn card on its 360-wide logical canvas.
@immutable
class TaliaShareMetrics {
  const TaliaShareMetrics._({
    required this.padding,
    required this.eyebrowSize,
    required this.signatureHeight,
    required this.logoSize,
    required this.qrSize,
    required this.wordmarkSize,
    required this.invitationSize,
    required this.referenceSize,
    required this.personalLineSize,
    required this.numeralSize,
    required this.numeralLabelSize,
    required this.statNumeralSize,
    required this.titleSize,
    required this.bodySize,
    required this.watermarkSize,
    required this.characterHeight,
    required this.heroInset,
    required this.medalSize,
    required this.gap,
    required List<double> verseSizes,
  }) : _verseSizes = verseSizes;

  static const double cardRadius = 24;
  static const double signatureRadius = 12;
  static const double qrRadius = 4;
  static const double barRadius = 2;

  final EdgeInsets padding;
  final double eyebrowSize;
  final double signatureHeight;
  final double logoSize;
  final double qrSize;
  final double wordmarkSize;
  final double invitationSize;
  final double referenceSize;
  final double personalLineSize;
  final double numeralSize;
  final double numeralLabelSize;
  final double statNumeralSize;
  final double titleSize;
  final double bodySize;
  final double watermarkSize;
  final double characterHeight;
  final double heroInset;
  final double medalSize;
  final double gap;

  /// Verse sizes for text of ≤80, ≤150, ≤250 and more characters.
  final List<double> _verseSizes;

  double verseSize(int length) {
    if (length <= 80) return _verseSizes[0];
    if (length <= 150) return _verseSizes[1];
    if (length <= 250) return _verseSizes[2];
    return _verseSizes[3];
  }

  static const square = TaliaShareMetrics._(
    padding: EdgeInsets.all(16),
    eyebrowSize: 10,
    signatureHeight: 52,
    logoSize: 36,
    qrSize: 46,
    wordmarkSize: 11,
    invitationSize: 9,
    referenceSize: 11,
    personalLineSize: 10,
    numeralSize: 64,
    numeralLabelSize: 14,
    statNumeralSize: 26,
    titleSize: 16,
    bodySize: 12,
    watermarkSize: 56,
    characterHeight: 96,
    heroInset: 14,
    medalSize: 64,
    gap: 6,
    verseSizes: [22, 19, 16, 13],
  );

  static const portrait = TaliaShareMetrics._(
    padding: EdgeInsets.all(20),
    eyebrowSize: 11,
    signatureHeight: 58,
    logoSize: 40,
    qrSize: 51,
    wordmarkSize: 12.5,
    invitationSize: 10,
    referenceSize: 12,
    personalLineSize: 11,
    numeralSize: 84,
    numeralLabelSize: 16,
    statNumeralSize: 30,
    titleSize: 18,
    bodySize: 13,
    watermarkSize: 68,
    characterHeight: 128,
    heroInset: 18,
    medalSize: 80,
    gap: 8,
    verseSizes: [26, 22, 19, 15.5],
  );

  /// Story keeps clear of platform UI: 40 top, 56 bottom.
  static const story = TaliaShareMetrics._(
    padding: EdgeInsets.fromLTRB(24, 40, 24, 56),
    eyebrowSize: 13,
    signatureHeight: 70,
    logoSize: 48,
    qrSize: 62,
    wordmarkSize: 14,
    invitationSize: 11.5,
    referenceSize: 14,
    personalLineSize: 12.5,
    numeralSize: 112,
    numeralLabelSize: 19,
    statNumeralSize: 36,
    titleSize: 21,
    bodySize: 15,
    watermarkSize: 90,
    characterHeight: 170,
    heroInset: 22,
    medalSize: 104,
    gap: 12,
    verseSizes: [30, 26, 23, 18.5],
  );

  static TaliaShareMetrics of(SocialShareFormat format) {
    return switch (format) {
      SocialShareFormat.square => square,
      SocialShareFormat.portrait => portrait,
      SocialShareFormat.story => story,
    };
  }
}

/// Centralized Arabic Typography for Share Cards
abstract class TaliaShareTypography {
  /// Reem Kufi — eyebrows, wordmark and numerals only. Never used for
  /// Quran, dua or dhikr text.
  static const String displayFontFamily = 'Reem_Kufi';

  /// Display style for the Kufi layer. The bundled font is variable, so
  /// the weight is also sent as a `wght` axis value.
  static TextStyle display({
    required Color color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.15,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: displayFontFamily,
      fontFamilyFallback: const [bodyFontFamily],
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontVariations: [FontVariation.weight(fontWeight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static const String quranFontFamily = 'Amiri';
  static const String bodyFontFamily = 'Noto_Naskh_Arabic';

  /// Emoji inside localized copy (📖 🌟 🎉 ✨) live outside the Arabic fonts.
  /// Real devices resolve them via platform fallback; declaring the common
  /// emoji families keeps offscreen exports and QA renders faithful too.
  /// Never applied to the Quran style — its shaping must stay pure Amiri.
  static const List<String> emojiFallback = [
    'Noto Color Emoji',
    'Segoe UI Emoji',
    'Apple Color Emoji',
  ];

  /// Quran verse style with authentic Arabic calligraphy presentation
  static TextStyle quranVerse({
    required Color color,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w400,
    double height = 2.0,
  }) {
    return TextStyle(
      fontFamily: quranFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: 0,
      wordSpacing: 1.5,
    );
  }

  /// Card Headline / Title
  static TextStyle title({
    required Color color,
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontFamily: quranFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.25,
    );
  }

  /// Body / Description
  static TextStyle body({
    required Color color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    double height = 1.6,
  }) {
    return TextStyle(
      fontFamily: bodyFontFamily,
      fontFamilyFallback: emojiFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Label & Badge text
  static TextStyle badge({
    required Color color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontFamily: bodyFontFamily,
      fontFamilyFallback: emojiFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.2,
    );
  }

  /// Metric highlight number
  static TextStyle metricValue({
    required Color color,
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontFamily: quranFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.0,
    );
  }
}
