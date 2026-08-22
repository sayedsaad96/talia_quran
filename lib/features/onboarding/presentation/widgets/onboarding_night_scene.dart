import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The committed night ground of the onboarding journey: a deep-teal sky,
/// a seeded star field, the golden mihrab horizon art, and the path of
/// light rising from the bottom. The scene is identical in light and dark
/// app themes — the journey begins at night, memorization's own hour.
///
/// [page] drives the ascent parallax (0 at the horizon, 1 at the fork):
/// the art scales up and fades while the star layers drift at two depths.
class OnboardingNightScene extends StatelessWidget {
  const OnboardingNightScene({super.key, required this.page});

  final double page;

  @override
  Widget build(BuildContext context) {
    final t = page.clamp(0.0, 1.0);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Deep-teal night gradient with a faint horizon lift near the bottom.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBackground,
                  AppColors.darkSurface,
                  AppColors.darkBackground,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Far star layer — drifts slower for depth.
          Transform.translate(
            offset: Offset(0, -18 * t),
            child: const CustomPaint(
              painter: _StarFieldPainter(seed: 7, starCount: 34, maxRadius: 1.1),
            ),
          ),

          // Near star layer with a few gold sparkles.
          Transform.translate(
            offset: Offset(0, -34 * t),
            child: const CustomPaint(
              painter: _StarFieldPainter(
                seed: 23,
                starCount: 14,
                maxRadius: 1.7,
                goldEvery: 4,
              ),
            ),
          ),

          // Golden mihrab horizon art — the ascent moment lives here: as the
          // visitor climbs toward the fork the sanctuary grows and dissolves
          // into the night.
          _HorizonArt(page: t),

          // Path of light rising from the bottom edge toward the art.
          const _PathOfLight(),
        ],
      ),
    );
  }
}

class _HorizonArt extends StatelessWidget {
  const _HorizonArt({required this.page});

  final double page;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.sizeOf(context).height * 0.58,
      child: IgnorePointer(
        child: Opacity(
          opacity: (1.0 - page * 1.35).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1.0 + page * 0.09,
            alignment: Alignment.bottomCenter,
            child: ShaderMask(
              // dstOut erases where the shader is opaque; keep the top by
              // running transparent→black so only the bottom edge melts
              // into the night.
              blendMode: BlendMode.dstOut,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black],
                stops: [0.80, 1.0],
              ).createShader(bounds),
              child: Image.asset(
                'assets/images/onboarding/splash_new.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PathOfLight extends StatelessWidget {
  const _PathOfLight();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 130,
        height: 190,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            gradient: RadialGradient(
              center: Alignment(0, 1.15),
              radius: 0.95,
              colors: [Color(0x2EF59E0B), Color(0x00F59E0B)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a deterministic star field; repainting is cheap and rare because
/// the layer sits behind a RepaintBoundary and only translates.
class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter({
    required this.seed,
    required this.starCount,
    required this.maxRadius,
    this.goldEvery = 0,
  });

  final int seed;
  final int starCount;
  final double maxRadius;
  final int goldEvery;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    for (var i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * maxRadius;
      final isGold = goldEvery > 0 && i % goldEvery == 0;
      final alpha = 0.22 + random.nextDouble() * 0.55;
      final paint =
          Paint()
            ..color =
                isGold
                    ? AppColors.goldLight.withValues(alpha: alpha + 0.15)
                    : AppColors.darkTextPrimary.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => false;
}
