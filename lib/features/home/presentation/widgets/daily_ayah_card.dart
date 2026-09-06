import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/daily_ayah/daily_ayah_result.dart';

class DailyAyahCard extends StatelessWidget {
  const DailyAyahCard({super.key, required this.result, required this.onRetry});

  final DailyAyahResult? result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    if (result == null) return const SizedBox.shrink();
    if (result is DailyAyahUnavailable) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.isArabic
                    ? 'يتعذر عرض آية اليوم الآن'
                    : 'Daily Ayah is unavailable right now',
                style: AppTypography.bodyMedium.copyWith(color: subtextColor),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(context.isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      );
    }

    final resolved = result! as DailyAyahResolved;
    final surahName = context.isArabic
        ? resolved.surah.nameAr
        : resolved.surah.nameEn;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: resolved.readerLocation == null
            ? null
            : () => context.push(resolved.readerLocation!),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppDecorations.bentoCard(
            isDark: isDark,
            accentGlow: AppColors.gold.withValues(alpha: 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      context.isArabic ? 'آية اليوم' : 'Daily Ayah',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      '$surahName · ${resolved.reference.ayahNumber}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTypography.labelSmall.copyWith(
                        color: subtextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                resolved.ayah.text,
                textDirection: TextDirection.rtl,
                style: AppTypography.titleMedium.copyWith(
                  color: textColor,
                  fontFamily: 'Amiri',
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
