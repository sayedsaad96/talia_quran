import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_spacing.dart';

/// Skeleton loader base box widget
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  final double width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E2D35) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF2A3F4B) : const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius ?? AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

/// Home Screen Skeleton Loader
class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.height < 650;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top App Bar / Greeting Placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(
                          width: size.width * 0.4,
                          height: 22,
                          radius: AppSpacing.radiusSm,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SkeletonBox(
                          width: size.width * 0.25,
                          height: 14,
                          radius: AppSpacing.radiusSm,
                        ),
                      ],
                    ),
                    const SkeletonBox(
                      width: 44,
                      height: 44,
                      radius: AppSpacing.radiusFull,
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.lg),

                // Hero Header Card
                SkeletonBox(
                  width: double.infinity,
                  height: isSmallScreen ? 140 : 170,
                  radius: AppSpacing.radiusXl,
                ),
                SizedBox(height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),

                // Next Action / Resume Session Card
                SkeletonBox(
                  width: double.infinity,
                  height: isSmallScreen ? 70 : 85,
                  radius: AppSpacing.radiusLg,
                ),
                SizedBox(height: isSmallScreen ? AppSpacing.sm : AppSpacing.md),

                // Bento Grid Cards
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SkeletonBox(
                        width: double.infinity,
                        height: isSmallScreen ? 110 : 130,
                        radius: AppSpacing.radiusLg,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: SkeletonBox(
                        width: double.infinity,
                        height: isSmallScreen ? 110 : 130,
                        radius: AppSpacing.radiusLg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress Screen Skeleton Loader
class ProgressSkeletonLoader extends StatelessWidget {
  const ProgressSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.pagePadding),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 100,
                    radius: AppSpacing.radiusLg,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 100,
                    radius: AppSpacing.radiusLg,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            SkeletonBox(
              width: double.infinity,
              height: 180,
              radius: AppSpacing.radiusXl,
            ),
            SizedBox(height: AppSpacing.lg),
            SkeletonBox(
              width: double.infinity,
              height: 180,
              radius: AppSpacing.radiusXl,
            ),
          ],
        ),
      ),
    );
  }
}
