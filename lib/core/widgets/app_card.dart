import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../constants/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.color,
    this.borderRadius,
    this.onTap,
    this.elevation = 0,
    this.border,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final double elevation;
  final BoxBorder? border;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);

    final cardDecoration = BoxDecoration(
      color: gradient == null ? (color ?? defaultColor) : null,
      gradient: gradient,
      borderRadius: radius,
      border:
          border ??
          Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 0.5,
          ),
      boxShadow: elevation > 0
          ? [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.06),
                blurRadius: elevation * 4,
                offset: Offset(0, elevation),
              ),
            ]
          : null,
    );

    Widget card = Container(
      margin: margin,
      decoration: cardDecoration,
      clipBehavior: clipBehavior,
      child: Material(
        type: MaterialType.transparency,
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (onTap != null) {
      card = ClipRRect(
        borderRadius: radius as BorderRadius? ?? BorderRadius.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius as BorderRadius?,
            splashColor: AppColors.primary.withValues(alpha: 0.06),
            highlightColor: AppColors.primary.withValues(alpha: 0.03),
            child: card,
          ),
        ),
      );
    }

    return card;
  }
}

/// Glass morphism card
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);

    return AppCard(
      margin: margin,
      borderRadius: radius,
      onTap: onTap,
      gradient: isDark
          ? AppColors.surfaceGlassDark
          : AppColors.surfaceGlassLight,
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.6),
        width: 1,
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
  }
}
