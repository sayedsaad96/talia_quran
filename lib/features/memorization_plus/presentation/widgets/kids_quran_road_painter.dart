import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kids_theme.dart';

/// The dashed road of the Quran journey map: enters from the previous row's
/// foot, bends through this row's foot, and leaves toward the next row's
/// foot, sampled along the same quadratic curves the rows are laid out with.
///
/// Segments behind the current house are lit gold; a coin marks the road
/// that still leads forward. At night the road gains fireflies and the coin
/// a glow; by day each island gets a soft ground shadow instead.
class KidsQuranRoadPainter extends CustomPainter {
  const KidsQuranRoadPainter({
    required this.hereX,
    required this.previousX,
    required this.nextX,
    required this.isFirst,
    required this.isLast,
    required this.incomingLit,
    required this.outgoingLit,
    required this.night,
    required this.seed,
    this.shimmer = 0,
  });

  /// Talia's foot x in this row (the road's bend point).
  final double hereX;

  /// Talia's foot x in the previous row (the road enters halfway to it).
  final double previousX;

  /// Talia's foot x in the next row (the road leaves halfway to it).
  final double nextX;

  final bool isFirst;
  final bool isLast;

  /// Whether the incoming segment (previous row to here) is lit.
  final bool incomingLit;

  /// Whether the outgoing segment (here to the next row) is lit.
  final bool outgoingLit;

  final bool night;

  /// Row index; varies the firefly positions per row.
  final int seed;

  /// 0 → 1 build shimmer that flashes the coin's highlight once.
  final double shimmer;

  @override
  void paint(Canvas canvas, Size size) {
    if (!night) _drawGroundShadow(canvas, size);
    if (!isFirst) {
      _drawDashes(canvas, incomingPath(size), lit: incomingLit);
    }
    if (!isLast) {
      _drawDashes(canvas, outgoingPath(size), lit: outgoingLit);
      if (outgoingLit) _drawCoin(canvas, size);
    }
    if (night) _drawFireflies(canvas, size);
  }

  /// Rows meet halfway between their feet, so the segment one row leaves on
  /// is exactly where the next row's segment enters. Both curves are
  /// vertical at that boundary, so the road reads as one smooth line.
  double get _enterX => (previousX + hereX) / 2;
  double get _leaveX => (hereX + nextX) / 2;

  /// From the boundary with the previous row to this row's foot.
  @visibleForTesting
  Path incomingPath(Size size) {
    final midY = size.height / 2;
    return Path()
      ..moveTo(_enterX, 0)
      ..quadraticBezierTo(_enterX, midY, hereX, midY);
  }

  /// From this row's foot to the boundary with the next row.
  @visibleForTesting
  Path outgoingPath(Size size) {
    final midY = size.height / 2;
    return Path()
      ..moveTo(hereX, midY)
      ..quadraticBezierTo(_leaveX, midY, _leaveX, size.height);
  }

  /// Splits the segment into 14 px dashes with 10 px gaps.
  void _drawDashes(Canvas canvas, Path path, {required bool lit}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = lit
          ? KidsTheme.goldStar
          : KidsTheme.creamParchment.withValues(alpha: 0.35);
    const dashLength = 14.0;
    const gapLength = 10.0;
    for (final metric in path.computeMetrics()) {
      for (
        var distance = 0.0;
        distance < metric.length;
        distance += dashLength + gapLength
      ) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
      }
    }
  }

  /// A gold coin at the outgoing curve's midpoint.
  void _drawCoin(Canvas canvas, Size size) {
    // Quadratic Bezier point at t = 0.5 of [outgoingPath].
    final midY = size.height / 2;
    final start = Offset(hereX, midY);
    final control = Offset(_leaveX, midY);
    final end = Offset(_leaveX, size.height);
    final center = Offset(
      (start.dx + 2 * control.dx + end.dx) / 4,
      (start.dy + 2 * control.dy + end.dy) / 4,
    );
    if (night) {
      canvas.drawCircle(
        center,
        11,
        Paint()
          ..color = KidsTheme.goldStar.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawCircle(center, 11, Paint()..color = KidsTheme.goldStar);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = KidsTheme.houseBrown,
    );
    canvas.drawPath(
      _starPath(center, outer: 5, inner: 2.5),
      Paint()..color = KidsTheme.goldLight,
    );
    final highlight = 0.6 * math.sin(math.pi * shimmer.clamp(0.0, 1.0));
    if (highlight > 0) {
      canvas.drawCircle(
        center - const Offset(2.5, 2.5),
        4,
        Paint()..color = Colors.white.withValues(alpha: highlight),
      );
    }
  }

  static Path _starPath(
    Offset center, {
    required double outer,
    required double inner,
  }) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point =
          center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  /// Soft ellipse under this row's island; the halo widget replaces it at
  /// night.
  void _drawGroundShadow(Canvas canvas, Size size) {
    final islandWidth = math.min(size.width * 0.40, 180.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(hereX, size.height - 8),
        width: islandWidth * 0.70,
        height: 12,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawFireflies(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()..color = KidsTheme.goldLight.withValues(alpha: 0.7);
    for (var i = 0; i < 3; i++) {
      final position = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(position, 2, paint);
    }
  }

  @override
  bool shouldRepaint(KidsQuranRoadPainter old) =>
      old.hereX != hereX ||
      old.previousX != previousX ||
      old.nextX != nextX ||
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.incomingLit != incomingLit ||
      old.outgoingLit != outgoingLit ||
      old.night != night ||
      old.seed != seed ||
      old.shimmer != shimmer;
}
