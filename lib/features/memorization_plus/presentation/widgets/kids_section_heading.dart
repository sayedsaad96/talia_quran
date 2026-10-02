import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../world/kids_world_palette.dart';

/// A heading drawn directly on the kids scene. It reads the palette in its
/// own build so it sees the `KidsBackground` scope above it (day or night),
/// which a parent that creates the background cannot do.
class KidsSectionHeading extends StatelessWidget {
  const KidsSectionHeading({
    super.key,
    required this.text,
    this.fontFamily,
    this.fontWeight,
  });

  final String text;
  final String? fontFamily;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: AppTypography.titleMedium.copyWith(
          color: KidsWorldPalette.of(context).onScene,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
