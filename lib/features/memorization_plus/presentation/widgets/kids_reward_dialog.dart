import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

class KidsRewardDialog extends StatelessWidget {
  const KidsRewardDialog({
    super.key,
    required this.starsEarned,
    this.showNextButton = true,
    this.onNext,
    this.onReturnToMap,
  });

  final int starsEarned;
  final bool showNextButton;
  final VoidCallback? onNext;
  final VoidCallback? onReturnToMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: KidsTheme.backgroundGradient,
        borderRadius: KidsTheme.cardRadius,
        boxShadow: KidsTheme.goldGlow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Image.asset(
              KidsTheme.starRewardAsset,
              width: 132,
              height: 132,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.kidsGamifiedWellDone,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontFamily: 'Amiri',
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _RewardPill(
                icon: Icons.star_rounded,
                label: context.l10n.kidsGamifiedEarnedStars(starsEarned),
                color: KidsTheme.goldStar,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReturnToMap,
                  icon: const Icon(Icons.map_rounded),
                  label: Text(context.l10n.kidsGamifiedReturnToMap),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.52),
                    ),
                    minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                    shape: const RoundedRectangleBorder(
                      borderRadius: KidsTheme.buttonRadius,
                    ),
                  ),
                ),
              ),
              if (showNextButton) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNext,
                    icon: Icon(
                      context.isArabic
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(context.l10n.kidsGamifiedStartMission),
                    style: FilledButton.styleFrom(
                      backgroundColor: KidsTheme.goldStar,
                      foregroundColor: KidsTheme.nightSkyDark,
                      minimumSize: const Size.fromHeight(
                        AppSpacing.buttonHeight,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: KidsTheme.buttonRadius,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
