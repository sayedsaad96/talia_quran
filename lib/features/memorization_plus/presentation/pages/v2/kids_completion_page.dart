// lib/features/memorization_plus/presentation/pages/v2/kids_completion_page.dart
//
// Kids V2 — Completion phase.
// Celebrates with stars earned and awards, then navigates back to Kids Home.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../cubits/kids_memorization_session_cubit.dart';

class KidsCompletionV2Page extends StatelessWidget {
  const KidsCompletionV2Page({super.key, required this.completed});

  final KMSCompleted completed;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    const primary = AppColors.kidsGreen;
    final stars = completed.starsEarned;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),

            // ── Stars display ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: i < stars ? 1.2 : 0.8,
                    duration: Duration(milliseconds: 300 + i * 100),
                    child: Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 52,
                      color: primary,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Celebration text ───────────────────────────────────────────
            Text(
              context.isArabic ? '🎉 أحسنت!' : '🎉 Well done!',
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.isArabic
                  ? 'لقد حفظت الآية بنجاح! استمر في الحفظ.'
                  : 'You memorized the ayah! Keep going.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),

            // ── New awards ─────────────────────────────────────────────────
            if (completed.awards.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.isArabic ? '🏆 شهادة جديدة!' : '🏆 New certificate!',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(color: primary),
              ),
            ],

            const Spacer(),

            // ── Back to Kids Home button ───────────────────────────────────
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              onPressed: () =>
                  context.go(AppRoutes.memorizationPlusKidsHome),
              icon: const Icon(Icons.home_rounded),
              label: Text(
                context.isArabic ? 'العودة للرئيسية' : 'Back to Home',
                style: AppTypography.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
