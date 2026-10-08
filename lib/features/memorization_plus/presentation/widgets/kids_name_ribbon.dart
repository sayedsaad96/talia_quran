import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kids_theme.dart';

/// A shiny ribbon in the Talia banner style that shows the child's [name]
/// in gold lettering. Drawn in code so it fits any name and either script;
/// the bundled `ribbon_banner.png` has the word «تالية» baked into its art.
class KidsNameRibbon extends StatelessWidget {
  const KidsNameRibbon({
    super.key,
    required this.name,
    this.width = 124,
    this.height = 68,
  });

  final String name;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fontSize = height * 0.34;
    final lettering = TextStyle(
      fontFamily: 'Amiri',
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      height: 1.1,
      letterSpacing: 0,
    );

    return Semantics(
      label: name,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _RibbonPainter()),
            Padding(
              // Keep the name on the front band, clear of the folded tails.
              padding: EdgeInsets.fromLTRB(
                width * 0.17,
                height * 0.1,
                width * 0.17,
                height * 0.1,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(0, fontSize * 0.07),
                      child: Text(
                        name,
                        maxLines: 1,
                        style: lettering.copyWith(
                          color: const Color(0xCC1E1B4B),
                        ),
                      ),
                    ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFF3B0),
                          Color(0xFFFBBF24),
                          Color(0xFFD97706),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        name,
                        maxLines: 1,
                        style: lettering.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the ribbon on a 100×56 design grid scaled to the widget size.
class _RibbonPainter extends CustomPainter {
  static const double _gridWidth = 100;
  static const double _gridHeight = 56;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _gridWidth, size.height / _gridHeight);

    final leftTail = Path()
      ..moveTo(3, 22)
      ..lineTo(24, 26)
      ..lineTo(24, 52)
      ..lineTo(3, 46)
      ..lineTo(10, 34)
      ..close();
    final rightTail = Path()
      ..moveTo(97, 22)
      ..lineTo(76, 26)
      ..lineTo(76, 52)
      ..lineTo(97, 46)
      ..lineTo(90, 34)
      ..close();
    final band = Path()
      ..moveTo(12, 14)
      ..cubicTo(34, 6, 66, 20, 88, 12)
      ..lineTo(88, 44)
      ..cubicTo(66, 52, 34, 38, 12, 46)
      ..close();

    const gold = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF3B0), Color(0xFFF59E0B), Color(0xFFB45309)],
    );
    const fullRect = Rect.fromLTWH(0, 0, _gridWidth, _gridHeight);
    final goldPaint = Paint()
      ..shader = gold.createShader(fullRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    // Soft glow so the ribbon lifts off the parchment card.
    canvas.drawPath(
      band,
      Paint()
        ..color = KidsTheme.reviewPurple.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    for (final tail in [leftTail, rightTail]) {
      canvas.drawPath(
        tail,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14B8A6), Color(0xFF3B5BDB)],
          ).createShader(fullRect),
      );
      canvas.drawPath(tail, goldPaint..strokeWidth = 1.1);
    }

    canvas.drawPath(
      band,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2F55D4), Color(0xFF6D3FC9), Color(0xFFA23AB8)],
        ).createShader(fullRect),
    );
    // Satin highlight along the upper half of the band.
    canvas.save();
    canvas.clipPath(band);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _gridWidth, 25),
      Paint()..color = Colors.white.withValues(alpha: 0.13),
    );
    canvas.restore();

    canvas.drawPath(band, goldPaint..strokeWidth = 1.6);

    // Fine inner gold line, following the band's curves.
    final inner = Path()
      ..moveTo(15, 19)
      ..cubicTo(35, 11.5, 65, 24.5, 85, 17)
      ..moveTo(15, 41)
      ..cubicTo(35, 33.5, 65, 46.5, 85, 39);
    canvas.drawPath(
      inner,
      Paint()
        ..color = KidsTheme.goldLight.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    _sparkle(canvas, const Offset(8, 9), 3.4);
    _sparkle(canvas, const Offset(93, 6), 2.6);
    _sparkle(canvas, const Offset(80, 52), 2.2);

    canvas.restore();
  }

  void _sparkle(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final r = i.isEven ? radius : radius * 0.28;
      final angle = i * math.pi / 4 - math.pi / 2;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFF3B0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
