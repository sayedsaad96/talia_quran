import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class TutorialGuideSection {
  const TutorialGuideSection({
    required this.title,
    required this.category,
    required this.icon,
    required this.whatItDoes,
    required this.howToOpen,
    required this.steps,
    required this.tips,
    required this.notes,
    required this.whenUseful,
    this.accentColor,
  });

  final String title;
  final String category;
  final IconData icon;
  final String whatItDoes;
  final String howToOpen;
  final List<String> steps;
  final List<String> tips;
  final List<String> notes;
  final String whenUseful;
  final Color? accentColor;

  bool matches(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return true;
    final text = [
      title,
      category,
      whatItDoes,
      howToOpen,
      whenUseful,
      ...steps,
      ...tips,
      ...notes,
    ].join(' ');
    return text.contains(normalized);
  }
}

class TutorialGuideSectionCard extends StatelessWidget {
  const TutorialGuideSectionCard({
    super.key,
    required this.section,
    this.initiallyExpanded = false,
  });

  final TutorialGuideSection section;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary =
        section.accentColor ??
        (isDark ? AppColors.primaryLight : AppColors.primary);
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return AppCard(
      borderRadius: BorderRadiusDirectional.circular(AppSpacing.radiusLg),
      border: Border.all(color: primary.withValues(alpha: 0.18)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md + 4,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md + 4,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(section.icon, color: primary, size: 22),
            ),
            title: Text(
              section.title,
              style: AppTypography.titleMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    section.category,
                    style: AppTypography.labelSmall.copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            iconColor: primary,
            collapsedIconColor: subtextColor,
            children: [
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              _GuideBlock(
                title: context.l10n.tutorialWhatItDoesTitle,
                body: section.whatItDoes,
                icon: Icons.info_outline_rounded,
                color: primary,
              ),
              _GuideBlock(
                title: context.l10n.tutorialHowToOpenTitle,
                body: section.howToOpen,
                icon: Icons.touch_app_rounded,
                color: AppColors.info,
              ),
              _GuideStepListBlock(
                title: context.l10n.tutorialStepsTitle,
                items: section.steps,
                icon: Icons.format_list_numbered_rtl_rounded,
                color: AppColors.success,
              ),
              if (section.tips.isNotEmpty)
                _GuidePillListBlock(
                  title: context.l10n.tutorialTipsTitle,
                  items: section.tips,
                  icon: Icons.lightbulb_outline_rounded,
                  color: primary,
                  backgroundColor: primary.withValues(alpha: 0.08),
                ),
              if (section.notes.isNotEmpty)
                _GuidePillListBlock(
                  title: context.l10n.tutorialNotesTitle,
                  items: section.notes,
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.08),
                ),
              _GuideBlock(
                title: context.l10n.tutorialWhenUsefulTitle,
                body: section.whenUseful,
                icon: Icons.check_circle_outline_rounded,
                color: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideBlock extends StatelessWidget {
  const _GuideBlock({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.06 : 0.04),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BlockTitle(title: title, icon: icon, color: color),
            const SizedBox(height: 6),
            Text(
              body,
              style: AppTypography.bodySmall.copyWith(
                color: subtextColor,
                height: 1.55,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStepListBlock extends StatelessWidget {
  const _GuideStepListBlock({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BlockTitle(title: title, icon: icon, color: color),
          const SizedBox(height: AppSpacing.xs),
          ...List.generate(items.length, (index) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      items[index],
                      style: AppTypography.bodySmall.copyWith(
                        color: subtextColor,
                        height: 1.5,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GuidePillListBlock extends StatelessWidget {
  const _GuidePillListBlock({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BlockTitle(title: title, icon: icon, color: color),
            const SizedBox(height: AppSpacing.xs),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtextColor,
                          height: 1.45,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
