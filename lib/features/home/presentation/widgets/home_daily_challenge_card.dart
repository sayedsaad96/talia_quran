import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../khatmah/domain/entities/khatmah_plan.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

class HomeDailyChallengeCard extends StatelessWidget {
  const HomeDailyChallengeCard({
    super.key,
    required this.state,
    required this.skin,
  });

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final khatmah = state.activeKhatmah;
    final int total;
    final int current;
    final String body;
    if (khatmah != null && khatmah.status == KhatmahStatus.active) {
      final target = khatmah.dailyTargetFor(now);
      total = (target.endPage - target.startPage + 1).clamp(1, 604);
      current = khatmah.dailyCompletedPages(now).clamp(0, total);
      body = context.l10n.homeDailyChallengePages(total);
    } else {
      final checklist = state.todayChecklist;
      // Without a checklist there is no real task count to show, so the card
      // must not invent one.
      if (checklist == null) return const SizedBox.shrink();
      total = checklist.tasks.length;
      current = checklist.completedCount;
      body = context.l10n.homeDailyChallengeTasks;
    }

    return GlassPanel(
      skin: skin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.local_fire_department_rounded,
            label: context.l10n.homeDailyChallenge,
            trailing: context.l10n.homeChallengeProgress(current, total),
            skin: skin,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: skin.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < total && i < 8; i++)
                _Dot(filled: i < current, skin: skin),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.label,
    required this.skin,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final HomeSkin skin;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: skin.gold),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: skin.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailing!,
            maxLines: 1,
            style: AppTypography.labelMedium.copyWith(
              color: skin.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.skin});
  final bool filled;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? skin.accent : Colors.transparent,
        border: Border.all(
          color: filled ? skin.accent : skin.progressTrack,
          width: 2,
        ),
      ),
      child: filled
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class HomeJourneyRingCard extends StatelessWidget {
  const HomeJourneyRingCard({
    super.key,
    required this.state,
    required this.skin,
  });

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final progress = state.progress;
    final khatmah = state.activeKhatmah;

    // The card must say which journey the user actually started, so each track
    // gets its own ring instead of one ambiguous "Quran" percentage.
    final hasMemorization =
        progress.memorizedAyahs > 0 || progress.startedAyahs > 0;
    final hasKhatmah =
        khatmah != null && khatmah.status != KhatmahStatus.completed;

    return GlassPanel(
      skin: skin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.auto_graph_rounded,
            label: context.l10n.homeQuranJourney,
            skin: skin,
          ),
          const SizedBox(height: AppSpacing.md),
          if (!hasMemorization && !hasKhatmah)
            _JourneyNotStarted(skin: skin)
          else ...[
            _JourneyRings(
              skin: skin,
              rings: [
                if (hasMemorization)
                  _JourneyRingData(
                    label: context.l10n.homeJourneyMemorization,
                    icon: Icons.menu_book_rounded,
                    value: progress.memorizedAyahsPercentage,
                    detail: context.l10n.homeJourneyMemorizedAyahs(
                      progress.memorizedAyahs,
                    ),
                    color: skin.accent,
                  ),
                if (hasKhatmah)
                  _JourneyRingData(
                    label: context.l10n.homeJourneyKhatmah,
                    icon: Icons.auto_stories_rounded,
                    value: khatmah.progressPercentage,
                    detail: context.l10n.homeJourneyKhatmahPages(
                      khatmah.completedPagesCount,
                      khatmah.completedPagesCount + khatmah.remainingPages,
                    ),
                    color: skin.gold,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MetaLine(
                    icon: Icons.local_fire_department_rounded,
                    text: context.l10n.homeStreakDays(progress.streakDays),
                    color: skin.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetaLine(
                    icon: Icons.bolt_rounded,
                    text: '${state.totalXp} ${context.l10n.xpLabel}',
                    color: skin.textSecondary,
                  ),
                ),
              ],
            ),
            if (hasMemorization) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      value: progress.memorizedSurahs,
                      label: context.l10n.homeSurahsCompleted,
                      color: skin.accent,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      value: progress.inProgressSurahs,
                      label: context.l10n.homeSurahsInProgress,
                      color: skin.gold,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      value: progress.remainingSurahs,
                      label: context.l10n.homeSurahsRemaining,
                      color: skin.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _JourneyRingData {
  const _JourneyRingData({
    required this.label,
    required this.icon,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final IconData icon;
  final double value;
  final String detail;
  final Color color;
}

class _JourneyRings extends StatelessWidget {
  const _JourneyRings({required this.rings, required this.skin});

  final List<_JourneyRingData> rings;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final diameter = rings.length > 1 ? 64.0 : 76.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rings.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _JourneyRing(
              data: rings[i],
              diameter: diameter,
              skin: skin,
            ),
          ),
        ],
      ],
    );
  }
}

class _JourneyRing extends StatelessWidget {
  const _JourneyRing({
    required this.data,
    required this.diameter,
    required this.skin,
  });

  final _JourneyRingData data;
  final double diameter;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final clamped = data.value.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: clamped,
                strokeWidth: 7,
                color: data.color,
                backgroundColor: skin.progressTrack,
              ),
              Text(
                '${(clamped * 100).round()}%',
                style: AppTypography.titleMedium.copyWith(
                  color: skin.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 14, color: data.color),
              const SizedBox(width: 4),
              Text(
                data.label,
                maxLines: 1,
                style: AppTypography.labelMedium.copyWith(
                  color: skin.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text(
          data.detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall.copyWith(color: skin.textSecondary),
        ),
      ],
    );
  }
}

class _JourneyNotStarted extends StatelessWidget {
  const _JourneyNotStarted({required this.skin});

  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.homeJourneyNotStartedTitle,
          style: AppTypography.titleMedium.copyWith(
            color: skin.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.homeJourneyNotStartedBody,
          style: AppTypography.bodySmall.copyWith(color: skin.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _JourneyStartButton(
              label: context.l10n.homeJourneyStartMemorization,
              icon: Icons.menu_book_rounded,
              route: AppRoutes.memorizationHub,
              skin: skin,
            ),
            _JourneyStartButton(
              label: context.l10n.khatmahStartAction,
              icon: Icons.auto_stories_rounded,
              route: AppRoutes.khatmahDashboard,
              skin: skin,
            ),
          ],
        ),
      ],
    );
  }
}

class _JourneyStartButton extends StatelessWidget {
  const _JourneyStartButton({
    required this.label,
    required this.icon,
    required this.route,
    required this.skin,
  });

  final String label;
  final IconData icon;
  final String route;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.push(route),
      style: TextButton.styleFrom(
        foregroundColor: skin.accent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
