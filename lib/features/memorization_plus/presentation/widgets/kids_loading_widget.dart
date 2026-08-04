import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

/// Gamified Loading Widget for Kids Mode
class KidsLoadingWidget extends StatelessWidget {
  const KidsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 48, color: KidsTheme.goldStar)
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 2000.ms)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 1000.ms,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'جاري التحضير...',
            style: AppTypography.titleSmall.copyWith(
              fontFamily: 'Amiri',
              color: KidsTheme.goldStar,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gamified Error Widget for Kids Mode
class KidsErrorWidget extends StatelessWidget {
  const KidsErrorWidget({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home_rounded, size: 64, color: KidsTheme.goldStar),
          const SizedBox(height: AppSpacing.md),
          Text(
            'يبدو أن شيئاً ما حدث!',
            style: AppTypography.titleMedium.copyWith(
              fontFamily: 'Amiri',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: KidsTheme.goldStar,
              foregroundColor: Colors.black,
            ),
            child: const Text('حاول مرة أخرى'),
          ),
        ],
      ),
    );
  }
}
