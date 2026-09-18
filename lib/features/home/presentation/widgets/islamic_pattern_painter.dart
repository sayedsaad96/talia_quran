import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints a subtle repeating Islamic 8-point star pattern.
/// Used as a faint texture overlay on the Hero Card.
class IslamicPatternPainter extends CustomPainter {
  IslamicPatternPainter({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const tileSize = 48.0;
    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = col * tileSize + tileSize / 2;
        final cy = row * tileSize + tileSize / 2;
        _drawStar(canvas, Offset(cx, cy), tileSize * 0.38, paint);
      }
    }
  }

  /// Draws an 8-point star at [center] with the given [radius].
  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;
    final innerRadius = radius * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final angle = (math.pi * i / points) - math.pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(IslamicPatternPainter oldDelegate) =>
      color != oldDelegate.color || opacity != oldDelegate.opacity;
}

/// Positioned overlay that paints the Islamic pattern on the right edge.
class IslamicPatternOverlay extends StatelessWidget {
  const IslamicPatternOverlay({
    super.key,
    required this.color,
    required this.opacity,
  });

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.rtl;
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRect(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SizedBox(
              width: 160,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: AlignmentDirectional.centerEnd,
                  end: AlignmentDirectional.centerStart,
                  colors: [Colors.white, Colors.transparent],
                ).createShader(bounds, textDirection: textDirection),
                blendMode: BlendMode.dstIn,
                child: CustomPaint(
                  painter: IslamicPatternPainter(
                    color: color,
                    opacity: opacity,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
