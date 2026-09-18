import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../streak/presentation/cubits/streak_cubit.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

/// Unified Bento-grid progress panel merging:
/// - Streak flame + weekly dots (from HomeMomentumStrip)
/// - Journey ring: memorization/khatmah circular progress (from HomeJourneyRingCard)
/// - XP + achievement level
class HomeUnifiedProgress extends StatelessWidget {
  const HomeUnifiedProgress({
    super.key,
    required this.state,
    required this.skin,
  });

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      skin: skin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top section: Streak + XP side-by-side
          Row(
            children: [
              // Streak flame
              _StreakSection(skin: skin),
              const SizedBox(width: AppSpacing.md),
              // XP counter
              _XpSection(totalXp: state.totalXp, skin: skin),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Divider
          Container(height: 1, color: skin.glassBorder),
          const SizedBox(height: AppSpacing.md),
          // Bottom section: Journey ring + weekly dots
          Row(
            children: [
              // Journey ring
              _JourneyRingCompact(state: state, skin: skin),
              const SizedBox(width: AppSpacing.md),
              // Weekly activity dots
              Expanded(child: _WeeklyDots(state: state, skin: skin)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakSection extends StatelessWidget {
  const _StreakSection({required this.skin});
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StreakCubit, StreakState>(
      builder: (context, streakState) {
        final days = streakState is StreakLoaded ? streakState.streak.currentStreak : 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 22, color: AppColors.streakOrange),
            const SizedBox(width: 6),
            Text(
              '$days',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.streakOrange,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.days,
              style: AppTypography.labelSmall.copyWith(
                color: skin.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _XpSection extends StatelessWidget {
  const _XpSection({required this.totalXp, required this.skin});
  final int totalXp;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 18, color: skin.gold),
        const SizedBox(width: 4),
        Text(
          '$totalXp XP',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: skin.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _JourneyRingCompact extends StatelessWidget {
  const _JourneyRingCompact({required this.state, required this.skin});
  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;
    final memPct = progress.totalAyahs > 0
        ? progress.memorizedAyahs / progress.totalAyahs
        : 0.0;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: memPct,
            strokeWidth: 5,
            color: skin.accent,
            backgroundColor: skin.progressTrack,
          ),
          Text(
            '${(memPct * 100).round()}%',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: skin.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyDots extends StatelessWidget {
  const _WeeklyDots({required this.state, required this.skin});
  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = today.subtract(Duration(days: 6 - i));
        final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final count = state.activityCountsByDay[key] ?? 0;
        final active = count > 0;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? skin.accent : skin.progressTrack,
          ),
        );
      }),
    );
  }
}
