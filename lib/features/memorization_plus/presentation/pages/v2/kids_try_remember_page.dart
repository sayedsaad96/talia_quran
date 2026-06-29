// lib/features/memorization_plus/presentation/pages/v2/kids_try_remember_page.dart
//
// Kids V2 — Phase 2: Try to Remember.
// Text is hidden. Child taps "I Remember!" to complete the ayah.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../cubits/kids_memorization_session_cubit.dart';

class KidsTryRememberPage extends StatelessWidget {
  const KidsTryRememberPage({super.key, required this.state});

  final KMSActive state;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    const primary = AppColors.kidsGreen;
    final cubit = context.read<KidsMemorizationSessionCubit>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Big brain emoji + title ───────────────────────────────────
            const Spacer(),
            const Text(
              '🧠',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 72),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.isArabic ? 'حاول تتذكر الآية!' : 'Try to remember!',
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.isArabic
                  ? 'النص مخفي الآن. هل تتذكر الآية؟'
                  : 'The text is hidden now. Do you remember the ayah?',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Hidden ayah card ─────────────────────────────────────────
            _HiddenAyahCard(isDark: isDark, primary: primary),
            const Spacer(),

            // ── Complete button ───────────────────────────────────────────
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              onPressed: cubit.completeAyah,
              icon: const Icon(Icons.check_circle_rounded, size: 28),
              label: Text(
                context.isArabic ? '✅ تذكرتها!' : '✅ I remember it!',
                style: AppTypography.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Go back to listen again ───────────────────────────────────
            TextButton.icon(
              onPressed: () {
                // Restart from learning phase so the child can listen again.
                cubit.startSession(
                  surahId: state.sessionState.surahId,
                  startAyah: state.sessionState.currentAyah.numberInSurah,
                );
              },
              icon: const Icon(Icons.replay_rounded),
              label: Text(
                context.isArabic
                    ? 'أريد الاستماع مرة أخرى'
                    : 'Listen again',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _HiddenAyahCard extends StatelessWidget {
  const _HiddenAyahCard({required this.isDark, required this.primary});

  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: 48,
          color: primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
