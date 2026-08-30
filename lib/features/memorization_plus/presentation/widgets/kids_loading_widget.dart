import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
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
          const SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(color: KidsTheme.goldStar),
                Icon(Icons.star_rounded, size: 24, color: KidsTheme.goldStar),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.kidsPreparing,
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
            context.l10n.kidsUnexpectedError,
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
            child: Text(context.l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}
