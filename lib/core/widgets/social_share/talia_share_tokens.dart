import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Talia Share System — Design Tokens & Aesthetics
abstract class TaliaShareColors {
  // ─── Talia Brand Palette ──────────────────────────────────────────────────
  static const Color royalTeal = Color(0xFF0D5C53);
  static const Color royalTealLight = Color(0xFF148275);
  static const Color royalTealDark = Color(0xFF042F2E);
  static const Color royalTealDeep = Color(0xFF021B19);
  static const Color luminousTurquoise = Color(0xFF7EE0C9);

  // ─── Warm & Metallic Gold Accents ─────────────────────────────────────────
  static const Color warmGold = Color(0xFFF59E0B);
  static const Color warmGoldLight = Color(0xFFFBBF24);
  static const Color warmGoldDark = Color(0xFFD97706);
  static const Color metallicGold = Color(0xFFE5C158);
  static const Color champagneGold = Color(0xFFF3E2A9);
  static const Color deepGold = Color(0xFF8B6508);

  // ─── Streak Ember & Medal Metals (shared across templates) ────────────────
  static const Color streakEmber = Color(0xFFFF8C42);
  static const Color streakEmberDeep = Color(0xFFFF6A00);
  static const Color streakEmberLight = Color(0xFFFFB03A);
  static const Color medalGold = Color(0xFFD4AF37);
  static const Color medalInk = Color(0xFF2C1E03);

  // ─── Ivory & Parchment Surfaces ───────────────────────────────────────────
  static const Color luminousIvory = Color(0xFFFAF8F2);
  static const Color softParchment = Color(0xFFFCFBF4);
  static const Color parchmentWarm = Color(0xFFF5EDD6);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // ─── Ambient Glow & Overlay Tints ─────────────────────────────────────────
  static const Color glowTeal = Color(0x331A6B5A);
  static const Color glowGold = Color(0x40F59E0B);
  static const Color glowAmber = Color(0x33D4A017);
  static const Color patternSubtleLight = Color(0x1AEAEEEC);
  static const Color patternSubtleDark = Color(0x0C0D5C53);
  static const Color kidsStarGold = Color(0xFFFBBF24);
  static const Color kidsSparkleTeal = Color(0xFF77D6C7);

  // ─── Text & Ink ───────────────────────────────────────────────────────────
  static const Color inkDeep = Color(0xFF1C2B2F);
  static const Color textPrimaryLight = Color(0xFFFAF7F0);
  static const Color textSecondaryLight = Color(0xFFC7D3CD);
  static const Color textPrimaryDark = Color(0xFF1A1209);
  static const Color textSecondaryDark = Color(0xFF5A6663);
}

/// Responsive Dimensions & Aspect Ratios
abstract class TaliaShareDimensions {
  /// Standard export canvas width.  Matches the fixed 360-logical export
  /// canvas so previews and exports lay out identically.
  static const double baseWidth = 360.0;

  // Aspect ratios
  static const double portraitRatio = 0.8; // 4:5 -> 1080x1350
  static const double squareRatio = 1.0; // 1:1 -> 1080x1080
  static const double storyRatio = 0.5625; // 9:16 -> 1080x1920

  static double aspectRatioFor(dynamic format) {
    final formatName = format.toString();
    if (formatName.contains('square')) return squareRatio;
    if (formatName.contains('story')) return storyRatio;
    return portraitRatio;
  }
}

/// Spacing System for Share Cards
abstract class TaliaShareSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

/// Centralized Arabic Typography for Share Cards
abstract class TaliaShareTypography {
  static const String quranFontFamily = 'Amiri';
  static const String bodyFontFamily = 'Noto_Naskh_Arabic';

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

/// Custom Painters for Luxury Islamic Framing & Geometry
class IslamicOctagramPainter extends CustomPainter {
  final Color color;
  final double density;

  const IslamicOctagramPainter({
    required this.color,
    this.density = 64.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width + density; x += density) {
      for (double y = 0; y < size.height + density; y += density) {
        _drawOctagram(canvas, Offset(x, y), density * 0.32, paint);
      }
    }
  }

  void _drawOctagram(Canvas canvas, Offset center, double radius, Paint paint) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawRect(rect, paint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(45 * math.pi / 180);
    canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: radius), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant IslamicOctagramPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.density != density;
}

/// Elegant Mihrab Arch Header Silhouette Painter
class MihrabArchPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const MihrabArchPainter({
    required this.color,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final topMargin = size.height * 0.04;
    final archWidth = size.width * 0.82;
    final archHeight = size.height * 0.18;
    final left = (size.width - archWidth) / 2;
    final right = left + archWidth;

    path.moveTo(left, topMargin + archHeight);
    path.lineTo(left, topMargin + archHeight * 0.35);
    path.cubicTo(
      left,
      topMargin,
      size.width / 2 - archWidth * 0.18,
      topMargin,
      size.width / 2,
      topMargin - 5,
    );
    path.cubicTo(
      size.width / 2 + archWidth * 0.18,
      topMargin,
      right,
      topMargin,
      right,
      topMargin + archHeight * 0.35,
    );
    path.lineTo(right, topMargin + archHeight);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MihrabArchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Golden Corner Arabesque Ornament
class GoldenCornerPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const GoldenCornerPainter({
    required this.color,
    this.opacity = 0.55,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 4)
      ..arcToPoint(
        const Offset(4, 0),
        radius: const Radius.circular(4),
      )
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);

    // Inner decorative corner dot
    final dotPaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(5, 5), 2.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant GoldenCornerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}
