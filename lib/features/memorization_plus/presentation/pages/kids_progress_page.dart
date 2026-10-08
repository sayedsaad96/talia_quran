import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../../home/domain/entities/activity_event.dart';
import '../../../home/presentation/widgets/home_activity_feed.dart'
    show activityTimeLabel;
import '../../domain/services/kids_achievements.dart';
import '../../domain/services/kids_progress_snapshot.dart';
import '../cubits/kids_progress_cubit.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_achievement_labels.dart';
import '../widgets/kids_loading_widget.dart';
import '../widgets/kids_progress_talia_cue.dart';
import '../widgets/kids_talia_companion.dart';
import '../widgets/kids_ui.dart';
import '../world/kids_world_palette.dart';

/// The kids track's own «تقدّمي»: level, stars, streak, memorized ayahs,
/// reading this week, milestones, certificates and recent activity. Kids
/// numbers only — the primary learner's progress never appears here.
class KidsProgressPage extends StatelessWidget {
  const KidsProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KidsProgressCubit>()..load(),
      child: const _KidsProgressView(),
    );
  }
}

class _KidsProgressView extends StatelessWidget {
  const _KidsProgressView();

  void _back(BuildContext context) => context.canPop()
      ? context.pop()
      : context.go(AppRoutes.memorizationPlusKidsHome);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidsTheme.nightSkyDark,
      body: BlocBuilder<KidsProgressCubit, KidsProgressState>(
        builder: (context, state) => switch (state) {
          KidsProgressLoading() => const Center(child: KidsLoadingWidget()),
          KidsProgressError() => KidsBackground(
            child: SafeArea(
              child: KidsErrorWidget(
                onRetry: () => context.read<KidsProgressCubit>().load(),
              ),
            ),
          ),
          KidsProgressLoaded(:final snapshot) => KidsProgressContent(
            snapshot: snapshot,
            onBack: () => _back(context),
          ),
        },
      ),
    );
  }
}

class KidsProgressContent extends StatelessWidget {
  const KidsProgressContent({
    super.key,
    required this.snapshot,
    required this.onBack,
    this.now,
  });

  final KidsProgressSnapshot snapshot;
  final VoidCallback onBack;

  /// Clock override for previews and tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KidsBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              KidsTopBar(
                title: l10n.kidsProgressTitle,
                subtitle: l10n.kidsProgressSubtitle,
                onBack: onBack,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    _TaliaLine(snapshot: snapshot, now: now ?? DateTime.now()),
                    const SizedBox(height: AppSpacing.md),
                    _SummaryCard(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.xl),
                    _SceneHeading(
                      icon: TaliaKidsIcons.trophy,
                      title: l10n.kidsAchievementsTitle,
                      trailing: l10n.kidsAchievementsCount(
                        context.numText(snapshot.unlockedCount),
                        context.numText(snapshot.achievements.length),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AchievementsGrid(achievements: snapshot.achievements),
                    const SizedBox(height: AppSpacing.xl),
                    _SceneHeading(
                      icon: TaliaKidsIcons.certificate,
                      title: l10n.myCertificates,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (snapshot.certificates.isEmpty)
                      _SceneNote(l10n.kidsProgressCertificatesEmpty)
                    else
                      for (final award in snapshot.certificates) ...[
                        _CertificateCard(award: award),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    const SizedBox(height: AppSpacing.xl),
                    _SceneHeading(
                      icon: TaliaKidsIcons.history,
                      title: l10n.kidsProgressRecentTitle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (snapshot.recentActivity.isEmpty)
                      _SceneNote(l10n.kidsProgressRecentEmpty)
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: _creamCard(),
                        child: Column(
                          children: [
                            for (final event in snapshot.recentActivity)
                              _ActivityRow(event: event),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _creamCard() => BoxDecoration(
  gradient: KidsTheme.parchmentGradient,
  borderRadius: KidsTheme.cardRadius,
  border: Border.all(color: KidsTheme.parchmentEdge, width: 1.5),
  boxShadow: KidsTheme.card25DShadow,
);

/// Door tone per milestone kind, from the kids door palette.
Color _metricDoor(KidsAchievementMetric metric) => switch (metric) {
  KidsAchievementMetric.ayahs => AppColors.kidsDoorTeal,
  KidsAchievementMetric.surahs => AppColors.kidsDoorViolet,
  KidsAchievementMetric.pages => AppColors.kidsDoorSky,
  KidsAchievementMetric.streak => AppColors.kidsDoorCoral,
  KidsAchievementMetric.stars => AppColors.kidsDoorSun,
};

/// Talia names the next step: a fresh milestone, the closest one ahead, or
/// the first one to reach. Never a shortfall.
class _TaliaLine extends StatelessWidget {
  const _TaliaLine({required this.snapshot, required this.now});

  final KidsProgressSnapshot snapshot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cue = kidsProgressTaliaCue(snapshot.achievements, now: now);
    final title = cue.achievement == null
        ? ''
        : kidsAchievementTitle(l10n, cue.achievement!.id);
    final message = switch (cue.kind) {
      KidsProgressCueKind.start => l10n.kidsProgressTaliaStart,
      KidsProgressCueKind.newAchievement => l10n.kidsProgressTaliaNew(title),
      KidsProgressCueKind.next => l10n.kidsProgressTaliaNext(title),
      KidsProgressCueKind.allDone => l10n.kidsProgressTaliaAllDone,
    };
    return KidsTaliaCompanion(
      key: const ValueKey('kids-progress-talia'),
      pose: cue.pose,
      message: message,
      animate: false,
      height: 96,
    );
  }
}

/// A heading drawn on the kids scene, in the journey map's voice.
class _SceneHeading extends StatelessWidget {
  const _SceneHeading({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = KidsWorldPalette.of(context);
    return Semantics(
      header: true,
      child: Row(
        children: [
          TaliaIcon(icon, color: KidsTheme.goldLight, size: 24),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: palette.onScene,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: palette.onScene.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                trailing!,
                style: AppTypography.labelMedium.copyWith(
                  color: palette.onScene,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SceneNote extends StatelessWidget {
  const _SceneNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        color: KidsWorldPalette.of(context).onSceneMuted,
        letterSpacing: 0,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.snapshot});

  final KidsProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const ValueKey('kids-progress-summary'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _creamCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const TaliaFeatureDoor(
                icon: TaliaKidsIcons.medal,
                color: AppColors.kidsDoorSun,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.kidsProgressLevel(context.numText(snapshot.level)),
                      style: AppTypography.headlineSmall.copyWith(
                        color: KidsTheme.inkOnParchment,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Semantics(
                      value: '${(snapshot.levelProgress * 100).round()}%',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: snapshot.levelProgress,
                          backgroundColor: KidsTheme.parchmentEdge,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            KidsTheme.goldStar,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: KidsTheme.parchmentEdge),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Stat(
                icon: TaliaKidsIcons.starFilled,
                door: AppColors.kidsDoorSun,
                value: snapshot.stars,
                label: l10n.kidsProgressStars,
              ),
              _Stat(
                icon: TaliaKidsIcons.flame,
                door: AppColors.kidsDoorCoral,
                value: snapshot.currentStreak,
                label: l10n.kidsProgressStreak,
              ),
              _Stat(
                icon: TaliaKidsIcons.hifz,
                door: AppColors.kidsDoorTeal,
                value: snapshot.memorizedAyahs,
                label: l10n.kidsProgressAyahs,
              ),
              _Stat(
                icon: TaliaKidsIcons.mushaf,
                door: AppColors.kidsDoorSky,
                value: snapshot.weekPages ?? 0,
                label: l10n.kidsProgressWeekPages,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.door,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color door;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MergeSemantics(
        child: Column(
          children: [
            TaliaFeatureDoor(icon: icon, color: door, size: 36),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.numText(value),
              style: AppTypography.titleLarge.copyWith(
                color: KidsTheme.inkOnParchment,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
                height: 1.2,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTypography.labelSmall.copyWith(
                color: KidsTheme.inkOnParchment,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.achievements});

  final List<KidsAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final columns = constraints.maxWidth >= 520 ? 4 : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final achievement in achievements)
              SizedBox(
                width: width,
                child: KidsAchievementBadge(achievement: achievement),
              ),
          ],
        );
      },
    );
  }
}

/// One milestone: an open coloured door once reached, otherwise a closed
/// slate tile with its progress toward the target.
class KidsAchievementBadge extends StatelessWidget {
  const KidsAchievementBadge({super.key, required this.achievement});

  final KidsAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final title = kidsAchievementTitle(context.l10n, achievement.id);
    final progressText = context.l10n.kidsAchievementProgress(
      context.numText(achievement.current),
      context.numText(achievement.target),
    );
    return Semantics(
      label: title,
      value: unlocked ? null : progressText,
      excludeSemantics: true,
      child: Container(
        key: ValueKey('kids-achievement-${achievement.id.name}'),
        // Same height reached or not, so the grid rows line up.
        constraints: const BoxConstraints(minHeight: 124),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: unlocked
            ? _creamCard()
            : BoxDecoration(
                color: KidsTheme.lockedSurface.withValues(alpha: 0.85),
                borderRadius: KidsTheme.cardRadius,
                border: Border.all(
                  color: KidsTheme.shellTextSecondary.withValues(alpha: 0.2),
                ),
              ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (unlocked)
              TaliaFeatureDoor(
                icon: kidsAchievementIcon(achievement.metric),
                color: _metricDoor(achievement.metric),
                size: 40,
              )
            else
              const SizedBox(
                height: 44,
                child: Center(
                  child: TaliaIcon(
                    TaliaKidsIcons.lock,
                    color: KidsTheme.shellTextSecondary,
                    size: 26,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                color: unlocked
                    ? KidsTheme.inkOnParchment
                    : KidsTheme.shellTextPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
              ),
            ),
            if (!unlocked) ...[
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: achievement.progress,
                  backgroundColor: KidsTheme.lockedSlate,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    KidsTheme.goldStar,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                progressText,
                style: AppTypography.labelSmall.copyWith(
                  color: KidsTheme.shellTextSecondary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.award});

  final CertificateAward award;

  @override
  Widget build(BuildContext context) {
    final title = context.isArabic
        ? award.titleAr
        : (award.titleEn ?? award.titleAr);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('kids-progress-certificate-${award.id}'),
        borderRadius: KidsTheme.cardRadius,
        onTap: () => context.push(
          AppRoutes.certificate,
          extra: <String, dynamic>{'award': award},
        ),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: _creamCard(),
          child: Row(
            children: [
              const TaliaFeatureDoor(
                icon: TaliaKidsIcons.certificate,
                color: AppColors.kidsDoorSun,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TaliaIcon(
                context.isArabic
                    ? TaliaKidsIcons.chevronBack
                    : TaliaKidsIcons.chevronForward,
                color: KidsTheme.inkOnParchment,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = event.surahId != null
        ? (context.isArabic
              ? SurahNames.nameAr(event.surahId)
              : SurahNames.nameEn(event.surahId))
        : event.pageNumber != null
        ? l10n.homeDailyWirdPage(context.numText(event.pageNumber!))
        : l10n.homeActivityReading;
    final kind = switch (event.kind) {
      ActivityEventKind.reading => l10n.homeActivityReading,
      ActivityEventKind.memorize => l10n.homeActivityMemorize,
      ActivityEventKind.review => l10n.homeActivityReview,
      ActivityEventKind.khatmah => l10n.homeActivityKhatmah,
    };
    final detail = event.startAyah != null && event.endAyah != null
        ? l10n.homeAyahRange(
            context.numText(event.startAyah!),
            context.numText(event.endAyah!),
          )
        : kind;
    final reading = event.kind == ActivityEventKind.reading;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          TaliaFeatureDoor(
            icon: reading ? TaliaKidsIcons.mushaf : TaliaKidsIcons.hifz,
            color: reading ? AppColors.kidsDoorSky : AppColors.kidsDoorTeal,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  '$detail${context.listSeparator}'
                  '${activityTimeLabel(l10n, event.occurredAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
