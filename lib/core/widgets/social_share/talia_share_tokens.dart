import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'social_share_model.dart';

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

  // ─── Night Sky & Illumination (reference visual language) ────────────────
  static const Color starlight = Color(0xFFEAF4EF);
  static const Color starlightWarm = Color(0xFFF6D989);
  static const Color moonCream = Color(0xFFF2E8C9);
  static const Color lanternGlow = Color(0xFFF2C94C);
  static const Color lanternAmber = Color(0xFFE0A93E);
  static const Color parchmentInk = Color(0xFF123D36);
  static const Color parchmentInkSoft = Color(0xFF3E5A53);

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

    // Inner parallel arc echoes the outer corner for a layered arabesque.
    final inner = Paint()
      ..color = color.withValues(alpha: opacity * 0.55)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final innerPath = Path()
      ..moveTo(0, size.height * 0.62)
      ..lineTo(0, 7)
      ..arcToPoint(
        const Offset(7, 0),
        radius: const Radius.circular(7),
      )
      ..lineTo(size.width * 0.62, 0);
    canvas.drawPath(innerPath, inner);

    // Inner decorative corner dot
    final dotPaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(5, 5), 2.2, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.34), 1.2,
        dotPaint..color = color.withValues(alpha: opacity * 0.7));
  }

  @override
  bool shouldRepaint(covariant GoldenCornerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}

/// Deterministic night-sky star field, seeded so preview and export match.
///
/// Stars are laid out on a jittered grid: mostly small dots with occasional
/// four-point sparkles. The same [seed] always produces the same sky.
class StarFieldPainter extends CustomPainter {
  final Color color;
  final Color sparkleColor;
  final double cellSize;
  final double opacity;
  final int seed;

  const StarFieldPainter({
    required this.color,
    required this.sparkleColor,
    this.cellSize = 46,
    this.opacity = 1,
    this.seed = 7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = _SeededRandom(seed);
    for (double x = 0; x < size.width; x += cellSize) {
      for (double y = 0; y < size.height; y += cellSize) {
        final px = x + rng.next() * cellSize;
        final py = y + rng.next() * cellSize;
        if (px > size.width || py > size.height) continue;
        final roll = rng.next();
        if (roll < 0.2) continue; // breathing room between stars
        final r = 0.5 + rng.next() * 1.1;
        if (roll > 0.84) {
          final arm = r * 3.4;
          final sparkle = Paint()
            ..color = sparkleColor
                .withValues(alpha: (0.3 + rng.next() * 0.4) * opacity)
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(px - arm, py), Offset(px + arm, py), sparkle);
          canvas.drawLine(Offset(px, py - arm), Offset(px, py + arm), sparkle);
        } else {
          canvas.drawCircle(
            Offset(px, py),
            r,
            Paint()
              ..color =
                  color.withValues(alpha: (0.16 + rng.next() * 0.4) * opacity),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarFieldPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.sparkleColor != sparkleColor ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.opacity != opacity ||
      oldDelegate.seed != seed;
}

class _SeededRandom {
  int _v;

  _SeededRandom(int seed) : _v = (seed * 2654435761) % 2147483647 + 1;

  double next() {
    _v = (_v * 48271) % 2147483647;
    return _v / 2147483647;
  }
}

/// Soft glowing crescent moon for the upper atmosphere of dark cards.
class CrescentMoonPainter extends CustomPainter {
  final Color color;
  final double glowOpacity;

  const CrescentMoonPainter({
    required this.color,
    this.glowOpacity = 0.14,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    // Layered halo reads as atmospheric glow without a blur filter.
    canvas.drawCircle(c, r * 1.85,
        Paint()..color = color.withValues(alpha: glowOpacity * 0.4));
    canvas.drawCircle(c, r * 1.4,
        Paint()..color = color.withValues(alpha: glowOpacity * 0.8));
    canvas.drawCircle(
        c, r * 1.12, Paint()..color = color.withValues(alpha: glowOpacity));

    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.66)),
      Path()
        ..addOval(Rect.fromCircle(
          center: Offset(c.dx - r * 0.3, c.dy - r * 0.12),
          radius: r * 0.58,
        )),
    );
    canvas.drawPath(moon, Paint()..color = color.withValues(alpha: 0.92));
  }

  @override
  bool shouldRepaint(covariant CrescentMoonPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.glowOpacity != glowOpacity;
}

/// A single hanging lantern: thin gold string, ring, domed body, warm glow.
///
/// Compose several instances at different [lineFraction] values to recreate
/// the reference's hanging-lantern strings.
class HangingLanternPainter extends CustomPainter {
  final Color gold;
  final Color glow;
  final double lineFraction;

  const HangingLanternPainter({
    required this.gold,
    required this.glow,
    this.lineFraction = 0.45,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final stringEnd = size.height * lineFraction;

    final line = Paint()
      ..color = gold.withValues(alpha: 0.5)
      ..strokeWidth = 0.9;
    canvas.drawLine(Offset(cx, 0), Offset(cx, stringEnd), line);

    final bodyCenter = Offset(cx, stringEnd + size.height * 0.34);
    final bodyRadius = size.width * 0.22;

    // Warm halo behind the lamp body.
    canvas.drawCircle(bodyCenter, bodyRadius * 2.4,
        Paint()..color = glow.withValues(alpha: 0.12));
    canvas.drawCircle(bodyCenter, bodyRadius * 1.6,
        Paint()..color = glow.withValues(alpha: 0.2));

    final stroke = Paint()
      ..color = gold.withValues(alpha: 0.85)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = glow.withValues(alpha: 0.3);

    // Hanging ring.
    canvas.drawCircle(Offset(cx, stringEnd + 3), 1.6, stroke..style = PaintingStyle.fill);

    // Domed top.
    final dome = Path()
      ..moveTo(cx - bodyRadius * 0.8, stringEnd + size.height * 0.14)
      ..quadraticBezierTo(cx, stringEnd + size.height * 0.02,
          cx + bodyRadius * 0.8, stringEnd + size.height * 0.14);
    canvas.drawPath(dome, stroke..style = PaintingStyle.stroke);

    // Body with a soft warm interior.
    final body = Rect.fromCenter(
      center: bodyCenter,
      width: bodyRadius * 2,
      height: size.height * 0.4,
    );
    final rrect =
        RRect.fromRectAndRadius(body, Radius.circular(body.width * 0.3));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);

    // Base finial.
    canvas.drawLine(
      Offset(cx, body.bottom),
      Offset(cx, body.bottom + 3),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant HangingLanternPainter oldDelegate) =>
      oldDelegate.gold != gold ||
      oldDelegate.glow != glow ||
      oldDelegate.lineFraction != lineFraction;
}

/// Gold botanical sprig — a curved stem with leaves, for arch bases and
/// parchment footer corners.
class BotanicalSprigPainter extends CustomPainter {
  final Color color;
  final bool mirror;

  const BotanicalSprigPainter({
    required this.color,
    this.mirror = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mirror) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final stem = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.55,
        size.width * 0.55,
        0,
      );
    canvas.drawPath(path, stem);

    final leaf = Paint()..color = color.withValues(alpha: 0.85);
    // Leaves alternate along the stem, shrinking toward the tip.
    final stops = [
      (0.18, 1.0),
      (0.34, -1.0),
      (0.5, 1.0),
      (0.66, -1.0),
      (0.82, 1.0),
    ];
    for (final (t, side) in stops) {
      final lx = _lerp(size.width * 0.36, size.width * 0.5, t);
      final ly = size.height * (1 - t * 0.95);
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(side * 0.9 - 0.4);
      final w = size.width * 0.34 * (1 - t * 0.45);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.4 * side, 0),
          width: w,
          height: w * 0.38,
        ),
        leaf,
      );
      canvas.restore();
    }

    if (mirror) canvas.restore();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant BotanicalSprigPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.mirror != mirror;
}

/// Subtle radial celebration rays behind medals and seals.
class RadialRaysPainter extends CustomPainter {
  final Color color;
  final int rayCount;
  final double opacity;

  const RadialRaysPainter({
    required this.color,
    this.rayCount = 12,
    this.opacity = 0.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final inner = size.shortestSide * 0.18;
    final outer = size.shortestSide * 0.52;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi - math.pi / 2;
      final spread = math.pi / rayCount * 0.42;
      final reach = i.isEven ? outer : outer * 0.78;
      final ray = Path()
        ..moveTo(center.dx + math.cos(angle - spread) * inner,
            center.dy + math.sin(angle - spread) * inner)
        ..lineTo(center.dx + math.cos(angle) * reach,
            center.dy + math.sin(angle) * reach)
        ..lineTo(center.dx + math.cos(angle + spread) * inner,
            center.dy + math.sin(angle + spread) * inner)
        ..close();
      canvas.drawPath(ray, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RadialRaysPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.rayCount != rayCount ||
      oldDelegate.opacity != opacity;
}
