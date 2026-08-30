import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

class PracticeSurahTile extends StatelessWidget {
  const PracticeSurahTile({
    super.key,
    required this.surah,
    required this.isDark,
    required this.primary,
  });

  final Surah surah;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: () async {
        final route =
            await MemorizationNavigationResolver(
              getIt<MemorizationPlusRepository>(),
            ).practiceSurahSessionLocation(
              surah.id,
              surahAyahCount: surah.ayahCount,
            );
        if (!context.mounted) return;
        await context.push(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  '${surah.id}',
                  style: AppTypography.labelMedium.copyWith(color: primary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.isArabic ? surah.nameAr : surah.nameEn,
                    style: context.isArabic
                        ? AppTypography.surahTitle.copyWith(
                            color: primary,
                            fontSize: 18,
                          )
                        : AppTypography.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${surah.ayahCount} ${context.l10n.ayahs}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              context.isArabic
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
          ],
        ),
      ),
    );
  }
}
