import 'package:flutter/material.dart';

import '../theme/kids_theme.dart';

/// K7 — responsive geometry for one journey-map segment. Resolves the house
/// card width and side margin from the available width so the winding path
/// keeps a real margin on narrow screens (176px cards left only ~144px of
/// path on a 320px screen). Floors at 136px for tiny phones.
({
  double cardWidth,
  double sideMargin,
}) resolveJourneySegmentMetrics(double totalWidth) {
  if (totalWidth < 360) {
    return (
      cardWidth: (totalWidth * 0.44).clamp(136.0, 156.0),
      sideMargin: 10.0,
    );
  }
  return (cardWidth: 176.0, sideMargin: 16.0);
}

/// Continuous winding dirt path painter that guarantees seamless C1 continuity
/// between consecutive segments at (midX, 0) and (midX, h).
class WindingPathPainter extends CustomPainter {
  const WindingPathPainter({
    required this.isLeft,
    required this.isFirst,
    required this.isLast,
    required this.totalWidth,
    required this.cardWidth,
    required this.sideMargin,
  });

  final bool isLeft;
  final bool isFirst;
  final bool isLast;
  final double totalWidth;
  final double cardWidth;
  final double sideMargin;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final midX = w * 0.5;
    final leftX = sideMargin + cardWidth * 0.5;
    final rightX = w - sideMargin - cardWidth * 0.5;
    final nodeX = isLeft ? leftX : rightX;
    final nodeY = h * 0.5;

    // Build the smooth path
    final path = Path();
    final startX = isFirst ? nodeX : midX;
    const startY = 0.0;
    path.moveTo(startX, startY);

    // Segment 1: from top to destination node
    path.cubicTo(
      startX,
      h * 0.18,
      nodeX,
      h * 0.28,
      nodeX,
      nodeY,
    );

    // Segment 2: from destination node to bottom midpoint
    final endX = isLast ? nodeX : midX;
    final endY = h;
    path.cubicTo(
      nodeX,
      h * 0.72,
      endX,
      h * 0.82,
      endX,
      endY,
    );

    // 1. Path Earth Border / Drop Shadow
    final borderPaint = Paint()
      ..color = KidsTheme.pathEdge
      ..strokeWidth = 32
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, borderPaint);

    // 2. Cobblestone / Dirt Road Surface
    final roadPaint = Paint()
      ..color = KidsTheme.pathDirt
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, roadPaint);

    // 3. Stepping Stone Platform under the Destination Building
    final stonePlatformCenter = Offset(nodeX, nodeY - 32);

    final stoneBasePaint = Paint()
      ..color = KidsTheme.pathEdge
      ..style = PaintingStyle.fill;
    canvas.drawCircle(stonePlatformCenter, 44, stoneBasePaint);

    final stoneSurfacePaint = Paint()
      ..color = KidsTheme.pathStone
      ..style = PaintingStyle.fill;
    canvas.drawCircle(stonePlatformCenter, 40, stoneSurfacePaint);

    final stoneRingPaint = Paint()
      ..color = KidsTheme.pathEdge.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(stonePlatformCenter, 32, stoneRingPaint);
  }

  @override
  bool shouldRepaint(covariant WindingPathPainter oldDelegate) {
    return oldDelegate.isLeft != isLeft ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.totalWidth != totalWidth;
  }
}

/// Lightweight landscape backdrop with gentle rolling hills silhouettes.
class LandscapeBackdropPainter extends CustomPainter {
  const LandscapeBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Horizon rolling green hill
    final hillPaint1 = Paint()
      ..color = const Color(0x334CAF50)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, h * 0.4)
      ..quadraticBezierTo(w * 0.35, h * 0.34, w * 0.7, h * 0.42)
      ..quadraticBezierTo(w * 0.88, h * 0.45, w, h * 0.41)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path1, hillPaint1);

    // Second hill silhouette
    final hillPaint2 = Paint()
      ..color = const Color(0x222E7D32)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, h * 0.48)
      ..quadraticBezierTo(w * 0.25, h * 0.53, w * 0.55, h * 0.47)
      ..quadraticBezierTo(w * 0.8, h * 0.43, w, h * 0.5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path2, hillPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
