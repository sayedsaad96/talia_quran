import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../theme/home_skin.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.skin,
    required this.child,
    this.padding,
    this.borderRadius,
    this.gradient,
  });

  final HomeSkin skin;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusXl);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final useBlur = HomeSkin.blurEnabled && !reduceMotion;

    final painted = DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? skin.glassFill : null,
        borderRadius: radius,
        border: Border.all(color: skin.glassBorder),
        boxShadow: skin.shadow,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: radius,
        child: useBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: painted,
              )
            : painted,
      ),
    );
  }
}
