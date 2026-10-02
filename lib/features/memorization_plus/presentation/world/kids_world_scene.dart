import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/kids_world_phase.dart';
import 'kids_world_palette.dart';

/// 2D scene behind kids screens. Day: sky, sun, drifting clouds, hills.
/// Night: deep sky, twinkling stars, a crescent moon, dark hills.
///
/// The clouds drift only while [animate] is true and reduced motion is off;
/// callers pause them during recitation playback and recording.
class KidsWorldScene extends StatefulWidget {
  const KidsWorldScene({
    super.key,
    required this.phase,
    required this.child,
    this.animate = true,
  });

  final KidsWorldPhase phase;
  final Widget child;
  final bool animate;

  @override
  State<KidsWorldScene> createState() => _KidsWorldSceneState();
}

class _KidsWorldSceneState extends State<KidsWorldScene>
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
  void didUpdateWidget(KidsWorldScene oldWidget) {
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
    final animating =
        widget.animate && !MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _ScenePainter(
              drift: _drift,
              phase: widget.phase,
              animating: animating,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.drift,
    required this.phase,
    required this.animating,
    required this.rtl,
  }) : super(repaint: drift);

  final Animation<double> drift;
  final KidsWorldPhase phase;
  final bool animating;
  final bool rtl;

  static final List<Offset> _stars = () {
    final r = math.Random(7);
    return List.generate(40, (_) => Offset(r.nextDouble(), r.nextDouble()));
  }();

  static const _clouds = [
    // (vertical position, scale, speed multiplier, phase)
    (0.12, 1.0, 1.0, 0.0),
    (0.27, 0.7, 1.6, 0.45),
    (0.44, 0.85, 1.25, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final palette = KidsWorldPalette.forPhase(phase);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.skyStops,
          stops: [0.0, 0.6, 1.0],
        ).createShader(rect),
    );

    if (phase == KidsWorldPhase.day) {
      // A soft sun glow in the upper corner.
      final sunCenter = Offset(size.width * 0.85, size.height * 0.07);
      canvas.drawCircle(
        sunCenter,
        size.shortestSide * 0.32,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  KidsWorldPalette.sunGlow.withValues(alpha: 0.85),
                  KidsWorldPalette.sunGlow.withValues(alpha: 0),
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
    } else {
      _drawNight(canvas, size, palette);
    }

    _drawHill(
      canvas,
      size,
      top: 0.80,
      bump: 0.06,
      color: palette.hills[0],
      flip: false,
    );
    _drawHill(
      canvas,
      size,
      top: 0.87,
      bump: 0.05,
      color: palette.hills[1],
      flip: true,
    );
  }

  void _drawNight(Canvas canvas, Size size, KidsWorldPalette palette) {
    final t = drift.value;
    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final alpha = animating
          ? 0.5 + 0.5 * math.sin(2 * math.pi * (t + i / 7))
          : 0.8;
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height * 0.6),
        1.0 + (i % 3) * 0.5,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }

    // Crescent: a pale disc with a sky-coloured disc biting into it, in the
    // top-start corner.
    final radius = size.shortestSide * 0.09;
    final center = Offset(
      rtl ? size.width * 0.85 : size.width * 0.15,
      size.height * 0.1,
    );
    final bite = Offset(rtl ? -radius * 0.55 : radius * 0.55, -radius * 0.2);
    canvas
      ..drawCircle(center, radius, Paint()..color = KidsWorldPalette.moon)
      ..drawCircle(
        center + bite,
        radius * 0.9,
        Paint()..color = palette.skyStops.first,
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
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.drift != drift ||
      oldDelegate.phase != phase ||
      oldDelegate.animating != animating ||
      oldDelegate.rtl != rtl;
}
