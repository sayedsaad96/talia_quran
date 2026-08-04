import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ReciterSelectorSheet extends StatelessWidget {
  const ReciterSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ReciterSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final reciterService = getIt<QuranReciterService>();

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.record_voice_over_rounded, color: primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.isArabic ? 'اختر القارئ المفضل' : 'Select Reciter',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder<QuranReciter>(
              valueListenable: reciterService.currentReciter,
              builder: (context, current, _) {
                return Column(
                  children: QuranReciter.values.map((reciter) {
                    final isSelected = reciter == current;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.08)
                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: isSelected
                              ? primary
                              : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          reciterService.setReciter(reciter);
                          Navigator.pop(context);
                        },
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary
                                : primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check_rounded : Icons.mic_rounded,
                            color: isSelected ? Colors.white : primary,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          context.isArabic ? reciter.nameAr : reciter.nameEn,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? primary
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                        trailing: isSelected
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  context.isArabic ? 'المحدد' : 'Active',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
