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
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.pagePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero area
            SkeletonBox(
              width: double.infinity,
              height: 180,
              radius: AppSpacing.radiusXl,
            ),
            SizedBox(height: AppSpacing.lg),
            // Bento grid top row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 140,
                    radius: AppSpacing.radiusXl,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 140,
                    radius: AppSpacing.radiusXl,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            // Bento grid bottom row
            Row(
              children: [
                Expanded(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 80,
                    radius: AppSpacing.radiusLg,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 80,
                    radius: AppSpacing.radiusLg,
                  ),
                ),
              ],
            ),
          ],
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
