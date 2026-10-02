import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/kids_theme.dart';

/// Bright 2D daytime scene behind a kids learning session: sky, slowly
/// drifting clouds and rolling hills, in the journey map's palette.
///
/// The clouds drift only while [animate] is true and reduced motion is off;
/// callers pause them during recitation playback and recording.
class KidsSessionScene extends StatefulWidget {
  const KidsSessionScene({super.key, required this.child, this.animate = true});

  final Widget child;
  final bool animate;

  @override
  State<KidsSessionScene> createState() => _KidsSessionSceneState();
}

class _KidsSessionSceneState extends State<KidsSessionScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
      value: 0.35,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDrift();
  }

  @override
  void didUpdateWidget(KidsSessionScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncDrift();
  }

  void _syncDrift() {
    final animate = widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (animate) {
      if (!_drift.isAnimating) unawaited(_drift.repeat());
    } else {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: _ScenePainter(drift: _drift)),
        ),
        widget.child,
      ],
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.drift}) : super(repaint: drift);

  final Animation<double> drift;

  static const _clouds = [
    // (vertical position, scale, speed multiplier, phase)
    (0.12, 1.0, 1.0, 0.0),
    (0.27, 0.7, 1.6, 0.45),
    (0.44, 0.85, 1.25, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KidsTheme.skyTop, Color(0xFFA8E0F0), KidsTheme.skyHorizon],
          stops: [0.0, 0.6, 1.0],
        ).createShader(rect),
    );

    // A soft sun glow in the upper corner.
    final sunCenter = Offset(size.width * 0.85, size.height * 0.07);
    canvas.drawCircle(
      sunCenter,
      size.shortestSide * 0.32,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFFFF3C4).withValues(alpha: 0.85),
                const Color(0xFFFFF3C4).withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: sunCenter,
                radius: size.shortestSide * 0.32,
              ),
            ),
    );

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final (top, scale, speed, phase) in _clouds) {
      final width = 120.0 * scale;
      final travel = size.width + width * 2;
      final t = (drift.value * speed + phase) % 1.0;
      _drawCloud(
        canvas,
        Offset(-width + travel * t, size.height * top),
        scale,
        cloudPaint,
      );
    }

    _drawHill(
      canvas,
      size,
      top: 0.80,
      bump: 0.06,
      color: KidsTheme.pathGrassLight,
      flip: false,
    );
    _drawHill(
      canvas,
      size,
      top: 0.87,
      bump: 0.05,
      color: KidsTheme.landscapeGrass,
      flip: true,
    );
  }

  void _drawCloud(Canvas canvas, Offset origin, double scale, Paint paint) {
    final s = scale;
    canvas
      ..drawCircle(origin + Offset(30 * s, 22 * s), 22 * s, paint)
      ..drawCircle(origin + Offset(60 * s, 14 * s), 28 * s, paint)
      ..drawCircle(origin + Offset(92 * s, 24 * s), 20 * s, paint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            origin.dx + 10 * s,
            origin.dy + 22 * s,
            104 * s,
            24 * s,
          ),
          Radius.circular(12 * s),
        ),
        paint,
      );
  }

  void _drawHill(
    Canvas canvas,
    Size size, {
    required double top,
    required double bump,
    required Color color,
    required bool flip,
  }) {
    final y = size.height * top;
    final rise = size.height * bump;
    final w = size.width;
    final path = Path()..moveTo(0, y);
    if (flip) {
      path.quadraticBezierTo(w * 0.3, y + rise, w * 0.6, y - rise * 0.4);
      path.quadraticBezierTo(w * 0.85, y - rise, w, y);
    } else {
      path.quadraticBezierTo(w * 0.25, y - rise, w * 0.5, y - rise * 0.2);
      path.quadraticBezierTo(w * 0.78, y + rise * 0.6, w, y - rise);
    }
    path
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) => oldDelegate.drift != drift;
}
