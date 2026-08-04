import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class TutorialGuideQuickStartCard extends StatelessWidget {
  const TutorialGuideQuickStartCard({super.key});

  static const _shortcuts = [
    _ShortcutItem(
      icon: Icons.home_rounded,
      label: 'الرئيسية',
      desc: 'الورد والتقدم اليومي',
      color: AppColors.primaryLight,
    ),
    _ShortcutItem(
      icon: Icons.menu_book_rounded,
      label: 'القرآن',
      desc: 'المصحف والقراءة',
      color: AppColors.info,
    ),
    _ShortcutItem(
      icon: Icons.psychology_alt_rounded,
      label: 'الحفظ',
      desc: 'الخطة والتحسين',
      color: AppColors.gold,
    ),
    _ShortcutItem(
      icon: Icons.spa_rounded,
      label: 'الأذكار',
      desc: 'الورد والعداد',
      color: AppColors.success,
    ),
    _ShortcutItem(
      icon: Icons.bar_chart_rounded,
      label: 'التقدم',
      desc: 'الشهادات والـ XP',
      color: AppColors.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.goldLight : AppColors.gold;

    return AppCard(
      gradient: isDark
          ? AppColors.heroGradientDark
          : AppColors.heroGradientLight,
      borderRadius: BorderRadiusDirectional.circular(AppSpacing.radiusXl),
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      border: Border.all(color: primary.withValues(alpha: 0.3)),
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                      'خريطة تالية السريعة',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'أهم 5 أقسام رئيسية لاستخدام التطبيق يومياً',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
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
              itemCount: _shortcuts.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final item = _shortcuts[index];
                return Container(
                  width: 90,
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                          color: item.color.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        item.desc,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'استخدم خانة البحث أو التصفية بالأسفل للوصول لأي شرح تفصيلي.',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
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

class _ShortcutItem {
  const _ShortcutItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String desc;
  final Color color;
}
