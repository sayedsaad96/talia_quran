import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/datasources/azkar_preferences_store.dart';

class FontScaleSelectorSheet extends StatelessWidget {
  const FontScaleSelectorSheet({
    super.key,
    required this.currentScale,
    required this.onScaleSelected,
    this.isDark = false,
  });

  final double currentScale;
  final ValueChanged<double> onScaleSelected;
  final bool isDark;

  static Future<void> show(
    BuildContext context, {
    AzkarPreferencesStore? store,
    bool? isDark,
  }) async {
    final effectiveStore = store ?? getIt<AzkarPreferencesStore>();
    final effectiveIsDark =
        isDark ?? Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: ValueListenableBuilder<double>(
            valueListenable: effectiveStore.fontScaleListenable,
            builder: (ctx, scale, _) {
              return FontScaleSelectorSheet(
                currentScale: scale,
                isDark: effectiveIsDark,
                onScaleSelected: (newScale) {
                  HapticFeedback.selectionClick();
                  effectiveStore.setFontScale(newScale);
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final hintColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final scales = [
      (label: 'صغير', scale: 0.85, sampleSize: 18.0),
      (label: 'متوسط', scale: 1.0, sampleSize: 22.0),
      (label: 'كبير', scale: 1.25, sampleSize: 26.0),
    ];

    return Material(
      color: surfaceColor,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkTextHint : AppColors.lightTextHint)
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.format_size_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'حجم خط الأذكار',
                    style: AppTypography.titleLarge.copyWith(
                      color: textColor,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Live Preview Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
                  key: const ValueKey('font-scale-preview-text'),
                  style: AppTypography.azkarText.copyWith(
                    color: textColor,
                    fontSize: 22.0 * currentScale,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 20),

              // Scale Buttons
              Row(
                children: scales.map((item) {
                  final isSelected = (currentScale - item.scale).abs() < 0.01;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => onScaleSelected(item.scale),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.lightSurfaceVariant),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ع',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: item.sampleSize,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : hintColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
