import 'package:flutter/material.dart';

import '../theme/home_skin.dart';

/// Page canvas for Home: the theme surface plus a soft gold halo behind the
/// header banner. The mosque photo itself belongs to [HomeHeroBanner] so it is
/// only ever drawn once, at a size where it is actually recognizable.
class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key, required this.skin, required this.child});

  final HomeSkin skin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: skin.scaffold,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            left: -40,
            right: -40,
            height: 380,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [skin.ambientGlow, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Full-bleed mosque banner that hosts the header content.
///
/// The photo is veiled to a consistent night tone in both themes, so the
/// content on top always uses [HomeSkin.textOnHero] and never depends on the
/// active brightness for contrast.
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key, required this.skin, required this.child});

  final HomeSkin skin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(bottom: Radius.circular(32));
    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF021210)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                HomeSkin.backgroundAsset,
                fit: BoxFit.cover,
                // The skyline sits along the bottom-left of the artwork.
                alignment: Alignment.bottomLeft,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: skin.heroVeil),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
