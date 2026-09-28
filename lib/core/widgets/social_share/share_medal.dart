import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Eight-point star medal used by achievement and certificate cards.
class ShareMedal extends StatelessWidget {
  const ShareMedal({
    super.key,
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('share-medal'),
      dimension: size,
      child: CustomPaint(
        painter: _EightPointStarPainter(color: color),
        child: Center(
          child: SizedBox.square(
            dimension: size * 0.5,
            child: FittedBox(child: child),
          ),
        ),
      ),
    );
  }
}

class _EightPointStarPainter extends CustomPainter {
  const _EightPointStarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final half = size.shortestSide * 0.36;
    final square = Rect.fromCenter(
      center: c,
      width: half * 2,
      height: half * 2,
    );
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.02);
    for (final angle in const [0.0, math.pi / 4]) {
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(angle)
        ..translate(-c.dx, -c.dy)
        ..drawRect(square, fill)
        ..drawRect(square, stroke)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EightPointStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
