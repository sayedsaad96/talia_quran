import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class TutorialGuideQuickStartCard extends StatelessWidget {
  const TutorialGuideQuickStartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shortcuts = [
      (
        icon: Icons.home_rounded,
        label: l10n.tutorialShortcutHomeLabel,
        desc: l10n.tutorialShortcutHomeDesc,
        color: AppColors.primaryLight,
      ),
      (
        icon: Icons.menu_book_rounded,
        label: l10n.tutorialShortcutQuranLabel,
        desc: l10n.tutorialShortcutQuranDesc,
        color: AppColors.accentBlue,
      ),
      (
        icon: Icons.psychology_alt_rounded,
        label: l10n.tutorialShortcutHifzLabel,
        desc: l10n.tutorialShortcutHifzDesc,
        color: AppColors.ambientGold,
      ),
      (
        icon: Icons.spa_rounded,
        label: l10n.tutorialShortcutAzkarLabel,
        desc: l10n.tutorialShortcutAzkarDesc,
        color: AppColors.success,
      ),
      (
        icon: Icons.bar_chart_rounded,
        label: l10n.tutorialShortcutProgressLabel,
        desc: l10n.tutorialShortcutProgressDesc,
        color: AppColors.desertSand,
      ),
    ];

    return AppCard(
      gradient: Theme.of(context).brightness == Brightness.dark
          ? AppColors.heroGradientDark
          : AppColors.heroGradientLight,
      borderRadius: BorderRadiusDirectional.circular(AppSpacing.radiusXl),
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tutorialQuickStartTitle,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.tutorialQuickStartSubtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shortcuts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final item = shortcuts[index];
                return Semantics(
                  label: '${item.label}, ${item.desc}',
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(item.icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.desc,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.tutorialQuickStartHint,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
