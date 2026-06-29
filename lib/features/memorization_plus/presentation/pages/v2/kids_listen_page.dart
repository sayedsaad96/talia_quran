// lib/features/memorization_plus/presentation/pages/v2/kids_listen_page.dart
//
// Kids V2 — Phase 1: Listen.
// The child sees the ayah text and listens to it (up to 3 times).
// "Next" button only enables after at least 1 playback completes.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/qcf_hifz_verse_view.dart';
import '../../cubits/kids_memorization_session_cubit.dart';

class KidsListenPage extends StatelessWidget {
  const KidsListenPage({super.key, required this.state});

  final KMSActive state;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    const primary = AppColors.kidsGreen;
    final session = state.sessionState;
    final ayah = session.currentAyah;
    final cubit = context.read<KidsMemorizationSessionCubit>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          // ── Progress dots ─────────────────────────────────────────────────
          _KidsProgressDots(
            total: session.totalAyahsInBlock,
            current: session.currentAyahIndex,
            passed: session.passedAyahNumbers.length,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Listen icon + title ───────────────────────────────────────────
          const Icon(Icons.headphones_rounded, size: 56, color: primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.isArabic ? '🎧 استمع للآية' : '🎧 Listen to the ayah',
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Ayah text card ────────────────────────────────────────────────
          _KidsAyahCard(
            isDark: isDark,
            child: QcfHifzVerseView(
              surahNumber: session.surahId,
              verseNumber: ayah.numberInSurah,
              fallbackText: ayah.text,
              isUnlocked: true,
              isMemorized: false,
              displayMode: HifzVerseDisplayMode.single,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Listen counter ────────────────────────────────────────────────
          _ListenCounter(
            current: state.listenLoopCount,
            max: state.maxListenLoops,
            primary: primary,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Play button ───────────────────────────────────────────────────
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: primary),
            onPressed: state.isPlaying ? null : cubit.playCurrentAyah,
            icon: Icon(
              state.isPlaying
                  ? Icons.volume_up_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(
              state.isPlaying
                  ? (context.isArabic ? 'يتم التشغيل...' : 'Playing...')
                  : (context.isArabic ? 'استمع' : 'Listen'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Next button (enabled after listening once) ────────────────────
          OutlinedButton.icon(
            onPressed: state.listenLoopCount > 0
                ? cubit.advanceToMemorizing
                : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              context.isArabic ? 'حاول التذكر' : 'Try to remember',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _KidsProgressDots extends StatelessWidget {
  const _KidsProgressDots({
    required this.total,
    required this.current,
    required this.passed,
  });

  final int total;
  final int current;
  final int passed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isPassed = i < passed;
        final isCurrent = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 24 : 12,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isPassed
                ? AppColors.kidsGreen
                : isCurrent
                    ? AppColors.kidsGreen.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}

class _ListenCounter extends StatelessWidget {
  const _ListenCounter({
    required this.current,
    required this.max,
    required this.primary,
  });

  final int current;
  final int max;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(max, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            i < current ? Icons.star_rounded : Icons.star_outline_rounded,
            color: primary,
            size: 28,
          ),
        );
      }),
    );
  }
}

class _KidsAyahCard extends StatelessWidget {
  const _KidsAyahCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.kidsGreen.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.kidsGreen.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
