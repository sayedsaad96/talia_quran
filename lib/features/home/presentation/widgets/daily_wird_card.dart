import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/home_cubit.dart';

class DailyWirdCard extends StatelessWidget {
  const DailyWirdCard({super.key, required this.state, required this.isDark});

  final HomeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pageNumber = state.dailyWirdPageDetail?.pageNumber ?? 1;
    String wird = context.l10n.homeDailyWirdPage(pageNumber.toString());

    if (state.dailyWirdPageDetail != null &&
        state.dailyWirdPageDetail!.surahs.isNotEmpty) {
      final surah = state.dailyWirdPageDetail!.surahs.first;
      final surahName = context.isArabic ? surah.nameAr : surah.nameEn;
      wird = context.l10n.homeDailyWirdSurahPage(
        pageNumber.toString(),
        surahName,
      );
    }

    final primaryText = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Semantics(
      button: true,
      label: context.l10n.dailyWird,
      hint: wird,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/quran/page/$pageNumber');
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppDecorations.bentoCard(
            isDark: isDark,
            accentGlow: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.dailyWird,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wird,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: primaryText,
                        fontFamily: context.isArabic ? 'Amiri' : null,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(context.forwardChevron, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
