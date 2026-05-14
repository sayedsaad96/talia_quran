import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
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
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return AppCard(
      borderRadius: BorderRadiusDirectional.circular(AppSpacing.radiusLg),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadiusDirectional.circular(
                AppSpacing.radiusMd,
              ),
            ),
            child: Icon(section.icon, color: primary, size: 22),
          ),
          title: Text(
            section.title,
            style: AppTypography.titleMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            section.category,
            style: AppTypography.labelSmall.copyWith(color: subtextColor),
          ),
          iconColor: primary,
          collapsedIconColor: subtextColor,
          children: [
            _GuideBlock(
              title: 'ما فائدتها؟',
              body: section.whatItDoes,
              icon: Icons.info_outline_rounded,
              color: primary,
            ),
            _GuideBlock(
              title: 'طريقة الفتح',
              body: section.howToOpen,
              icon: Icons.touch_app_rounded,
              color: AppColors.info,
            ),
            _GuideListBlock(
              title: 'خطوات الاستخدام',
              items: section.steps,
              icon: Icons.format_list_numbered_rtl_rounded,
              color: AppColors.success,
            ),
            _GuideListBlock(
              title: 'نصائح سريعة',
              items: section.tips,
              icon: Icons.lightbulb_outline_rounded,
              color: AppColors.gold,
            ),
            _GuideListBlock(
              title: 'تنبيهات شائعة',
              items: section.notes,
              icon: Icons.error_outline_rounded,
              color: AppColors.warning,
            ),
            _GuideBlock(
              title: 'متى تستخدمها؟',
              body: section.whenUseful,
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.primary,
            ),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BlockTitle(title: title, icon: icon, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(
              color: subtextColor,
              height: 1.55,
            ),
          ),
          Divider(
            height: AppSpacing.lg,
            color: (isDark ? AppColors.darkDivider : AppColors.lightDivider)
                .withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

class _GuideListBlock extends StatelessWidget {
  const _GuideListBlock({
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
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 7),
                    child: Icon(Icons.circle, size: 6, color: color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodySmall.copyWith(
                        color: subtextColor,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: AppSpacing.lg,
            color: (isDark ? AppColors.darkDivider : AppColors.lightDivider)
                .withValues(alpha: 0.7),
          ),
        ],
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
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
