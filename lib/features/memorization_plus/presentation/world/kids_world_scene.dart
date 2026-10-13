import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/services/kids_world_growth_snapshot.dart';
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
    this.growth = KidsWorldGrowthSnapshot.none,
  });

  final KidsWorldPhase phase;
  final Widget child;
  final bool animate;

  /// Decorative plants and blossoms for saved milestones; static, so they
  /// never move with or without reduced motion.
  final KidsWorldGrowthSnapshot growth;

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
              growth: widget.growth,
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
    this.growth = KidsWorldGrowthSnapshot.none,
  }) : super(repaint: drift);

  final Animation<double> drift;
  final KidsWorldPhase phase;
  final bool animating;
  final bool rtl;
  final KidsWorldGrowthSnapshot growth;

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

  final Paint _skyPaint = Paint();
  final Paint _sunPaint = Paint();
  final Paint _cloudPaint = Paint()..color = KidsWorldPalette.cloud;
  final Paint _starPaint = Paint()..style = PaintingStyle.fill;
  final Paint _moonPaint = Paint()..color = KidsWorldPalette.moon;
  final Paint _bitePaint = Paint();
  final Paint _hillPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = KidsWorldPalette.forPhase(phase);
    final rect = Offset.zero & size;
    _skyPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: palette.skyStops,
      stops: const [0.0, 0.6, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, _skyPaint);

    if (phase == KidsWorldPhase.day) {
      // A soft sun glow in the upper corner.
      final sunCenter = Offset(size.width * 0.85, size.height * 0.07);
      _sunPaint.shader =
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
          );
      canvas.drawCircle(sunCenter, size.shortestSide * 0.32, _sunPaint);

      for (final (top, scale, speed, phase) in _clouds) {
        final width = 120.0 * scale;
        final travel = size.width + width * 2;
        final t = (drift.value * speed + phase) % 1.0;
        _drawCloud(
          canvas,
          Offset(-width + travel * t, size.height * top),
          scale,
          _cloudPaint,
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
    // Plants stand on the front hill's surface.
    if (!growth.isEmpty) _drawGrowth(canvas, size);
  }

  /// Height of the front hill (top 0.87, bump 0.05, flipped) at [x], from
  /// the same two quadratic curves [_drawHill] draws.
  static double _frontHillY(Size size, double x) {
    final w = size.width;
    final y = size.height * 0.87;
    final rise = size.height * 0.05;
    final mid = Offset(w * 0.6, y - rise * 0.4);
    final (p0, c, p1) = x <= w * 0.6
        ? (Offset(0, y), Offset(w * 0.3, y + rise), mid)
        : (mid, Offset(w * 0.85, y - rise), Offset(w, y));
    // x(t) is monotonic on each segment: bisect for t.
    var lo = 0.0;
    var hi = 1.0;
    Offset at(double t) =>
        p0 * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + p1 * (t * t);
    for (var i = 0; i < 20; i++) {
      final t = (lo + hi) / 2;
      if (at(t).dx < x) {
        lo = t;
      } else {
        hi = t;
      }
    }
    return at((lo + hi) / 2).dy;
  }

  void _drawNight(Canvas canvas, Size size, KidsWorldPalette palette) {
    final t = drift.value;
    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final alpha = animating
          ? 0.5 + 0.5 * math.sin(2 * math.pi * (t + i / 7))
          : 0.8;
      _starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height * 0.6),
        1.0 + (i % 3) * 0.5,
        _starPaint,
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
    _bitePaint.color = palette.skyStops.first;
    canvas
      ..drawCircle(center, radius, _moonPaint)
      ..drawCircle(center + bite, radius * 0.9, _bitePaint);
  }

  /// Fixed slots across the width (as fractions), so the same milestones
  /// always draw the same world; mirrored in RTL.
  static const _plantSlots = [
    0.08, 0.92, 0.22, 0.78, 0.35, 0.65, 0.15, 0.85, 0.48, 0.28, 0.72, 0.57,
  ];

  final Paint _trunkPaint = Paint();
  final Paint _leafPaint = Paint();
  final Paint _blossomPaint = Paint();

  void _drawGrowth(Canvas canvas, Size size) {
    final day = phase == KidsWorldPhase.day;
    _trunkPaint.color = day ? const Color(0xFF8D6E63) : const Color(0xFF3E2C26);
    _leafPaint.color = day ? const Color(0xFF2E8B4E) : const Color(0xFF1C5A43);
    final unit = size.shortestSide * 0.03;
    double groundAt(double x) => _frontHillY(size, x) + unit * 0.3;
    for (var i = 0; i < growth.plants; i++) {
      final fraction = _plantSlots[i % _plantSlots.length];
      final x = size.width * (rtl ? 1 - fraction : fraction);
      final base = groundAt(x);
      // A gentle variety of heights, fixed per slot.
      final height = unit * (2.2 + (i % 3) * 0.5);
      canvas
        ..drawRect(
          Rect.fromLTWH(x - unit * 0.15, base - height, unit * 0.3, height),
          _trunkPaint,
        )
        ..drawCircle(Offset(x, base - height), unit * 0.95, _leafPaint);
    }
    const blossomColors = [
      Color(0xFFF9A8D4),
      Color(0xFFFDE68A),
      Color(0xFFC4B5FD),
      Color(0xFFFDBA74),
    ];
    const blossomSlots = [0.12, 0.42, 0.70, 0.52];
    for (var i = 0; i < growth.blossoms; i++) {
      final fraction = blossomSlots[i % blossomSlots.length];
      final x = size.width * (rtl ? 1 - fraction : fraction);
      final center = Offset(x, groundAt(x) - unit * 0.8);
      _blossomPaint.color = blossomColors[i % blossomColors.length]
          .withValues(alpha: day ? 1 : 0.75);
      for (var petal = 0; petal < 5; petal++) {
        final angle = petal * 2 * math.pi / 5;
        canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * unit * 0.4,
          unit * 0.3,
          _blossomPaint,
        );
      }
      canvas.drawCircle(center, unit * 0.22, _trunkPaint);
    }
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
    _hillPaint.color = color;
    canvas.drawPath(path, _hillPaint);
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.drift != drift ||
      oldDelegate.phase != phase ||
      oldDelegate.animating != animating ||
      oldDelegate.rtl != rtl ||
      oldDelegate.growth != growth;
}
