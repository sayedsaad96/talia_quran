import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class TutorialGuideQuickStartCard extends StatelessWidget {
  const TutorialGuideQuickStartCard({super.key});

  static const _steps = [
    'ابدأ من الشريط السفلي: الرئيسية، القرآن، الحفظ، الأذكار، التقدم.',
    'اقرأ وردك اليومي أو افتح المصحف من تبويب القرآن، ثم أكّد الصفحة كمقروءة.',
    'اختر مسار الحفظ المناسب، أو افتح الحفظ الذكي لإنشاء خطة يومية أو وضع الأطفال.',
    'راجع تقدمك من تبويب التقدم، واضبط التذكيرات والمظهر من الإعدادات.',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return AppCard(
      gradient: isDark
          ? AppColors.heroGradientDark
          : AppColors.heroGradientLight,
      borderRadius: BorderRadiusDirectional.circular(AppSpacing.radiusXl),
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      border: Border.all(color: primary.withValues(alpha: 0.24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadiusDirectional.circular(
                    AppSpacing.radiusMd,
                  ),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ابدأ من هنا',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'خريطة سريعة لأهم خطوات استخدام تالية',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(_steps.length, (index) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _steps[index],
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'كل شرح في الأسفل يوضح الفائدة، طريقة الفتح، الخطوات، والنصائح.',
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : textColor.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
