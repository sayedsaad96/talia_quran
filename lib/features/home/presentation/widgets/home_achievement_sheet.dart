import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/services/xp_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../theme/home_skin.dart';

class HomeAchievementSheet extends StatelessWidget {
  const HomeAchievementSheet({
    super.key,
    required this.progress,
    required this.totalXp,
    required this.isKids,
    this.skin,
  });

  final OverallProgress progress;
  final int totalXp;
  final bool isKids;
  final HomeSkin? skin;

  @override
  Widget build(BuildContext context) {
    final themeSkin =
        skin ?? HomeSkin.forBrightness(Theme.of(context).brightness);
    final xpService = getIt<XpService>();
    final level = xpService.getCurrentLevel(totalXp);
    final progressRatio = xpService.progressToNextLevel(totalXp);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: themeSkin.scaffold,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border(
          top: BorderSide(color: themeSkin.glassBorder, width: 1.5),
        ),
        boxShadow: themeSkin.shadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeSkin.glassBorder,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: themeSkin.gold.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeSkin.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: themeSkin.gold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.homeAchievementSheetTitle,
                          style: AppTypography.titleMedium.copyWith(
                            color: themeSkin.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          context.l10n.homeAchievementSheetSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: themeSkin.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: themeSkin.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.xs,
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                ),
                children: [
                  // Level overview card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [
                          themeSkin.accent.withValues(alpha: 0.15),
                          themeSkin.gold.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: themeSkin.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  level.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  level.name,
                                  style: AppTypography.titleLarge.copyWith(
                                    color: themeSkin.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: themeSkin.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Text(
                                '$totalXp ${context.l10n.xpLabel}',
                                style: AppTypography.labelMedium.copyWith(
                                  color: themeSkin.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                          child: LinearProgressIndicator(
                            value: progressRatio.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor:
                                themeSkin.glassBorder.withValues(alpha: 0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(themeSkin.gold),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.isArabic
                              ? '${(progressRatio * 100).toInt()}% نحو المستوى التالي'
                              : '${(progressRatio * 100).toInt()}% to next rank',
                          style: AppTypography.labelSmall.copyWith(
                            color: themeSkin.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Achievements list
                  Text(
                    context.isArabic ? 'الأوسمة والإنجازات' : 'Badges & Achievements',
                    style: AppTypography.titleSmall.copyWith(
                      color: themeSkin.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (progress.achievements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(
                        child: Text(
                          context.isArabic
                              ? 'واصل التلاوة لكسب الأوسمة'
                              : 'Keep reciting to earn badges',
                          style: AppTypography.bodySmall.copyWith(
                            color: themeSkin.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final achievement in progress.achievements) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: themeSkin.glassFill,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: themeSkin.glassBorder),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: achievement.isUnlocked
                                    ? themeSkin.gold.withValues(alpha: 0.2)
                                    : themeSkin.textSecondary.withValues(alpha: 0.1),
                                child: Icon(
                                  achievement.isUnlocked
                                      ? Icons.military_tech_rounded
                                      : Icons.lock_outline_rounded,
                                  color: achievement.isUnlocked
                                      ? themeSkin.gold
                                      : themeSkin.textSecondary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.localizedAchievementTitle(achievement),
                                      style: AppTypography.titleSmall.copyWith(
                                        color: themeSkin.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      context.localizedAchievementDescription(achievement),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: themeSkin.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (achievement.isUnlocked)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
