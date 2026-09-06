part of 'home_page.dart';

class _HeroHeader extends StatefulWidget {
  const _HeroHeader({required this.state, required this.isDark});

  final HomeLoaded state;
  final bool isDark;

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader> {
  String _greetingText(BuildContext context) => switch (widget.state.greeting) {
    'morning' => context.l10n.greetingMorning,
    'afternoon' => context.l10n.greetingAfternoon,
    'evening' => context.l10n.greetingEvening,
    _ => context.l10n.greetingNight,
  };

  IconData _greetingIcon() => switch (widget.state.greeting) {
    'morning' => Icons.wb_sunny_rounded,
    'afternoon' => Icons.wb_cloudy_rounded,
    'evening' => Icons.wb_twilight_rounded,
    _ => Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context) {
    final bottomColor = widget.isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/mosque_bg.png',
              fit: BoxFit.contain,
              cacheWidth: 1024,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF020A08).withValues(alpha: 0.88),
                    const Color(0xFF0D3F34).withValues(alpha: 0.54),
                    bottomColor.withValues(alpha: 0.98),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _greetingIcon(),
                        color: Colors.white.withValues(alpha: 0.82),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BlocBuilder<ProfileCubit, ProfileState>(
                          builder: (context, profileState) {
                            final hasName =
                                profileState is ProfileLoaded &&
                                profileState.profile.hasName;
                            final name = hasName
                                ? ', ${profileState.profile.displayName}'
                                : '';
                            return Text(
                              '${_greetingText(context)}$name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _HeroIconButton(
                        icon: Icons.settings_suggest_rounded,
                        tooltip: context.l10n.settings,
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Text(
                        'تاليــة',
                        style: AppTypography.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Amiri',
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _AchievementRow(
                    progress: widget.state.progress,
                    isKids: widget.state.isKids,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon),
      color: Colors.white.withValues(alpha: 0.82),
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        minimumSize: const Size(48, 48),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.progress, required this.isKids});

  final OverallProgress progress;
  final bool isKids;

  @override
  Widget build(BuildContext context) {
    final readingAchievements = progress.achievements.where(
      (a) => a.isUnlocked && a.category == AchievementCategory.reading,
    );
    final memAchievements = progress.achievements.where(
      (a) => a.isUnlocked && a.category == AchievementCategory.memorization,
    );
    final highestReading = readingAchievements.isNotEmpty
        ? readingAchievements.last
        : null;
    final highestMem = memAchievements.isNotEmpty ? memAchievements.last : null;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (highestReading != null)
          _AchievementBadge(
            achievement: highestReading,
            isDark: true,
            isKids: isKids,
          ),
        if (highestMem != null)
          _AchievementBadge(
            achievement: highestMem,
            isDark: true,
            isKids: isKids,
          ),
        if (highestReading == null && highestMem == null)
          _AchievementBadge(achievement: null, isDark: true, isKids: isKids),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.achievement,
    required this.isDark,
    required this.isKids,
  });

  final Achievement? achievement;
  final bool isDark;
  final bool isKids;

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        MediaQuery.sizeOf(context).width - (AppSpacing.pagePadding * 2);
    String title = context.l10n.levelBeginner;
    IconData icon = Icons.stars_rounded;
    Color color = const Color(0xFFC0C0C0);
    String categoryLabel = '';

    if (achievement != null) {
      final best = achievement!;
      title = context.localizedAchievementTitle(best);
      if (best.category == AchievementCategory.memorization) {
        color = const Color(0xFFFFD700);
        icon = Icons.workspace_premium_rounded;
        categoryLabel = context.l10n.memorization;
      } else {
        color = const Color(0xFF82C8E5);
        icon = Icons.menu_book_rounded;
        categoryLabel = context.l10n.reading;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      onTap: () {
        final certs = getIt<AchievementService>().getEarnedCertificates(
          isKids: isKids,
        );
        final award =
            achievement?.category == AchievementCategory.memorization &&
                certs.isNotEmpty
            ? certs.first
            : null;
        if (award == null) {
          context.go(AppRoutes.progress);
          return;
        }
        context.push(
          AppRoutes.certificate,
          extra: {
            'award': award,
            'userName': context.read<ProfileCubit>().state is ProfileLoaded
                ? (context.read<ProfileCubit>().state as ProfileLoaded)
                      .profile
                      .displayName
                : context.l10n.taliaUser,
          },
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              if (categoryLabel.isNotEmpty) ...[
                Text(
                  categoryLabel,
                  style: AppTypography.titleSmall.copyWith(
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 16,
                  width: 1.5,
                  color: color.withValues(alpha: 0.4),
                ),
              ],
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyWirdCard extends StatelessWidget {
  const _DailyWirdCard({required this.state, required this.isDark});

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
        surahName,
        pageNumber.toString(),
      );
    }

    final primaryText = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return InkWell(
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
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
                      height: 1.35,
                    ),
                    textDirection: context.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
                ],
              ),
            ),
            Icon(
              context.isArabic
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.progress,
    required this.totalXp,
    required this.isDark,
    this.isKids = false,
    this.kidsPoints = 0,
  });

  final OverallProgress progress;
  final int totalXp;
  final bool isDark;
  final bool isKids;
  final int kidsPoints;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    // Always show memorization completion for the active path.
    final progressPercent = progress.memorizedAyahsPercentage;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isKids ? Icons.stars_rounded : Icons.insights_rounded,
                color: primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isKids
                      ? context.l10n.homeKidsProgress
                      : context.l10n.homeYourProgress,
                  style: AppTypography.titleMedium.copyWith(
                    color: textColor,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(progressPercent * 100).toStringAsFixed(0)}%',
                style: AppTypography.titleSmall.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: context.l10n.shareProgress,
                onPressed: () {
                  final l10n = context.l10n;
                  showModalBottomSheet<void>(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.insights_rounded),
                            title: Text(l10n.shareProgress),
                            onTap: () {
                              Navigator.pop(ctx);
                              SocialShareSheet.show(
                                context,
                                SocialShareData.progress(progress: progress),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.psychology_rounded),
                            title: Text(l10n.shareMemorizationMilestone),
                            onTap: () {
                              Navigator.pop(ctx);
                              SocialShareSheet.show(
                                context,
                                SocialShareData.memorization(
                                  ayahsCount: progress.memorizedAyahs,
                                  surahsCount: progress.memorizedSurahs,
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.local_fire_department_rounded,
                            ),
                            title: Text(l10n.shareConsistencyStreak),
                            onTap: () {
                              Navigator.pop(ctx);
                              SocialShareSheet.show(
                                context,
                                SocialShareData.streak(
                                  streakDays: progress.streakDays,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.share_rounded, size: 18, color: primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 8,
              backgroundColor: primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isKids)
            // ── Kids: 2×2 grid showing reading, memorization, points, XP
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ProgressMetricPill(
                        label: context.l10n.reading,
                        value: '${progress.readPagesCount}',
                        icon: Icons.menu_book_rounded,
                        color: primary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ProgressMetricPill(
                        label: context.l10n.hifz,
                        value: '${progress.memorizedAyahs}',
                        icon: Icons.auto_stories_rounded,
                        color: AppColors.accentBlue,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressMetricPill(
                        label: context.l10n.points,
                        value: '$kidsPoints',
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.gold,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ProgressMetricPill(
                        label: 'XP',
                        value: '$totalXp',
                        icon: Icons.bolt_rounded,
                        color: AppColors.streakOrange,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            // ── Adults: 3-pill row (reading, memorization, XP)
            LayoutBuilder(
              builder: (context, constraints) {
                final metrics = [
                  _ProgressMetricPill(
                    label: context.l10n.reading,
                    value:
                        '${progress.readPagesCount}/${progress.totalQuranPages}',
                    icon: Icons.menu_book_rounded,
                    color: primary,
                    isDark: isDark,
                  ),
                  _ProgressMetricPill(
                    label: context.l10n.hifz,
                    value: '${progress.memorizedAyahs}/${progress.totalAyahs}',
                    icon: Icons.auto_stories_rounded,
                    color: AppColors.accentBlue,
                    isDark: isDark,
                  ),
                  _ProgressMetricPill(
                    label: 'XP',
                    value: '$totalXp',
                    icon: Icons.bolt_rounded,
                    color: AppColors.streakOrange,
                    isDark: isDark,
                  ),
                ];

                if (constraints.maxWidth >= 440) {
                  return Row(
                    children: [
                      Expanded(child: metrics[0]),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: metrics[1]),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: metrics[2]),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: metrics[0]),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: metrics[1]),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(width: double.infinity, child: metrics[2]),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProgressMetricPill extends StatelessWidget {
  const _ProgressMetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            style: AppTypography.labelSmall.copyWith(color: subTextColor),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 190,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.55,
      children: [
        _QuickActionButton(
          icon: Icons.menu_book_rounded,
          title: context.l10n.homeActionQuran,
          subtitle: context.l10n.homeActionReadToday,
          color: AppColors.primary,
          route: AppRoutes.quran,
          isDark: isDark,
        ),
        _QuickActionButton(
          icon: Icons.psychology_alt_rounded,
          title: context.l10n.homeActionTodaysPlan,
          subtitle: context.l10n.homeActionContinuePlan,
          color: AppColors.accentBlue,
          route: AppRoutes.memorizationHub,
          isDark: isDark,
        ),
        _QuickActionButton(
          icon: Icons.insights_rounded,
          title: context.l10n.homeActionProgress,
          subtitle: context.l10n.homeActionReviewGains,
          color: AppColors.streakOrange,
          route: AppRoutes.progress,
          isDark: isDark,
        ),
        _QuickActionButton(
          icon: Icons.settings_rounded,
          title: context.l10n.homeActionSettings,
          subtitle: context.l10n.homeActionTuneApp,
          color: AppColors.accentPurple,
          route: AppRoutes.settings,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentGuardianToolsCard extends StatelessWidget {
  const _ParentGuardianToolsCard({required this.isDark});

  final bool isDark;

  Future<void> _openDashboard(BuildContext context) async {
    final location = await MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    ).parentDashboardLocation();
    if (context.mounted) unawaited(context.push(location));
  }

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.family_restroom_rounded, color: primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeParentToolsTitle,
                  style: AppTypography.titleMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.homeParentToolsSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: subTextColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    onPressed: () => unawaited(_openDashboard(context)),
                    icon: const Icon(Icons.dashboard_rounded, size: 18),
                    label: Text(context.l10n.homeParentToolsAction),
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

class _SignInNudgeBanner extends StatefulWidget {
  const _SignInNudgeBanner({required this.isDark});

  final bool isDark;

  @override
  State<_SignInNudgeBanner> createState() => _SignInNudgeBannerState();
}

class _SignInNudgeBannerState extends State<_SignInNudgeBanner> {
  static const _dismissedKey = 'sign_in_nudge_dismissed';
  bool _dismissed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final dismissed =
        getIt<SharedPreferences>().getBool(_dismissedKey) ?? false;
    if (mounted) {
      setState(() {
        _dismissed = dismissed;
        _loaded = true;
      });
    }
  }

  Future<void> _dismiss() async {
    await getIt<SharedPreferences>().setBool(_dismissedKey, true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _dismissed) return const SizedBox.shrink();

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) return const SizedBox.shrink();

        final primary = widget.isDark
            ? AppColors.primaryLight
            : AppColors.primary;
        final textColor = widget.isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
        final subTextColor = widget.isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.md,
            AppSpacing.pagePadding,
            0,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: primary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_circle_rounded, color: primary, size: 26),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.guestUpgradeTitle,
                        style: AppTypography.titleSmall.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${context.l10n.guestUpgradeMessage} '
                        '${context.l10n.guestUpgradeLocalProgress}',
                        style: AppTypography.labelSmall.copyWith(
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: Text(context.l10n.signIn),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: Icon(Icons.close_rounded, color: subTextColor),
                  tooltip: context.l10n.later,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TutorialPromptBanner extends StatefulWidget {
  const _TutorialPromptBanner({required this.isDark});

  final bool isDark;

  @override
  State<_TutorialPromptBanner> createState() => _TutorialPromptBannerState();
}

class _TutorialPromptBannerState extends State<_TutorialPromptBanner> {
  static const _seenKey = 'home_tutorial_prompt_seen';
  bool _visible = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = getIt<SharedPreferences>().getBool(_seenKey) ?? false;
    if (mounted) {
      setState(() {
        _visible = !seen;
        _loaded = true;
      });
    }
  }

  Future<void> _dismiss() async {
    await getIt<SharedPreferences>().setBool(_seenKey, true);
    if (mounted) setState(() => _visible = false);
  }

  Future<void> _openGuide() async {
    await getIt<SharedPreferences>().setBool(_seenKey, true);
    if (!mounted) return;
    setState(() => _visible = false);
    await context.push(AppRoutes.tutorialGuide);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_visible) return const SizedBox.shrink();

    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: primary.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: primary, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.homeTourTitle,
                    style: AppTypography.titleSmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    context.l10n.homeTourDesc,
                    style: AppTypography.labelSmall.copyWith(
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _openGuide,
              child: Text(context.l10n.homeTourGuideAction),
            ),
            IconButton(
              onPressed: _dismiss,
              icon: Icon(Icons.close_rounded, color: subTextColor),
              tooltip: context.l10n.notNow,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeSessionCard extends StatelessWidget {
  const _ResumeSessionCard({
    required this.location,
    required this.isDark,
    required this.isKids,
  });

  final String location;
  final bool isDark;
  final bool isKids;

  String? _normalizedLocation() {
    return location;
  }

  @override
  Widget build(BuildContext context) {
    final resumeLocation = _normalizedLocation();
    if (resumeLocation == null) return const SizedBox.shrink();

    final presentationData = const ResumeSessionPresentationMapper().map(
      ResumeSessionPresentationInput(
        route: resumeLocation,
        isArabic: context.isArabic,
        l10n: context.l10n,
      ),
    );
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(presentationData.icon, color: primary, size: 34),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentationData.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: textColor,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  presentationData.subtitle,
                  style: AppTypography.bodySmall.copyWith(color: subTextColor),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => unawaited(context.push(resumeLocation)),
            child: Text(context.l10n.resumeAction),
          ),
          IconButton(
            onPressed: () async {
              await getIt<AppSessionService>().clearLastRestorableLocation();
              if (context.mounted) unawaited(context.read<HomeCubit>().load());
            },
            icon: Icon(Icons.close_rounded, color: subTextColor),
            tooltip: context.l10n.notNow,
          ),
        ],
      ),
    );
  }
}

class _NextBestActionCard extends StatefulWidget {
  const _NextBestActionCard({
    required this.state,
    required this.isDark,
    this.isKids = false,
  });

  final HomeLoaded state;
  final bool isDark;
  final bool isKids;

  @override
  State<_NextBestActionCard> createState() => _NextBestActionCardState();
}

class _NextBestActionCardState extends State<_NextBestActionCard> {
  String? _goal;

  @override
  void initState() {
    super.initState();
    _goal = getIt<SharedPreferences>().getString('user_primary_goal');
  }

  (String, String, IconData, String) _action(BuildContext context) {
    final coach = widget.state.coachRecommendation;
    if (coach != null) {
      return _coachAction(context, coach);
    }

    if (widget.isKids) {
      return (
        context.l10n.homeCurrentMission,
        context.l10n.homeStartKidsMission,
        Icons.star_rounded,
        AppRoutes.memorizationHub,
      );
    }
    if (widget.state.customPlan != null) {
      return (
        context.l10n.homeContinueTodaysPlan,
        context.l10n.planReadySmallStep,
        Icons.psychology_alt_rounded,
        AppRoutes.memorizationHub,
      );
    }
    if (widget.state.dailyWirdPageDetail != null) {
      return (
        context.l10n.readTodaysPortion,
        context.l10n.onePageMakesProgress,
        Icons.menu_book_rounded,
        '/quran/page/${widget.state.dailyWirdPageDetail!.pageNumber}',
      );
    }
    if (_goal == 'azkar') {
      return (
        context.l10n.timeForDhikr,
        context.l10n.startShortAzkarNow,
        Icons.volunteer_activism_rounded,
        '/azkar',
      );
    }
    if (_goal == 'child') {
      return (
        context.l10n.homeCurrentMission,
        context.l10n.homeChooseKidsPath,
        Icons.auto_stories_rounded,
        AppRoutes.memorizationHub,
      );
    }
    return (
      context.l10n.homeTodaysPlan,
      context.l10n.chooseReadingOrMemorization,
      Icons.auto_awesome_rounded,
      AppRoutes.memorizationHub,
    );
  }

  (String, String, IconData, String) _coachAction(
    BuildContext context,
    SmartCoachRecommendation coach,
  ) {
    final surahLabel = _coachSurahLabel(context, coach.surahId);
    final ayahLabel = _coachAyahLabel(context, coach);

    return switch (coach.kind) {
      SmartCoachRecommendationKind.reviewDueNear => (
        context.l10n.journeyReviewBeforeNewTitle,
        context.l10n.journeyReviewBeforeNewDesc('$surahLabel$ayahLabel'),
        Icons.history_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.reviewDueFar => (
        context.l10n.journeyLongTermReviewTitle,
        context.l10n.journeyLongTermReviewDesc('$surahLabel$ayahLabel'),
        Icons.schedule_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.memorizedReviewDue => (
        context.l10n.smartCoachMemorizedReviewDueTitle,
        context.l10n.smartCoachMemorizedReviewDueSubtitle(
          _coachSurahName(context, coach.surahId),
        ),
        Icons.verified_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.reviewWeakAyah => (
        context.l10n.journeyReviewDifficultAyahTitle,
        context.l10n.journeyReviewDifficultAyahDesc('$surahLabel$ayahLabel'),
        Icons.healing_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.continueDailyPlan => (
        context.l10n.journeyContinueDailyPlanTitle,
        context.l10n.journeyContinueDailyPlanDesc(
          coach.completedCount ?? 0,
          coach.totalCount ?? 0,
        ),
        Icons.today_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.memorizeNewAyahs => (
        context.l10n.journeyMemorizeNewAyahsTitle,
        context.l10n.journeyMemorizeNewAyahsDesc('$surahLabel$ayahLabel'),
        Icons.auto_awesome_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.kidsCurrentMission => (
        context.l10n.journeyCurrentMissionTitle,
        context.l10n.journeyCurrentMissionDesc,
        Icons.star_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.continueV2Session => (
        context.l10n.journeyContinueSessionTitle,
        context.l10n.journeyContinueSessionDesc(surahLabel),
        Icons.play_circle_fill_rounded,
        coach.route,
      ),
    };
  }

  String _coachSurahName(BuildContext context, int? surahId) {
    if (surahId == null) {
      return context.l10n.journeyFallbackSurah;
    }
    return context.isArabic
        ? SurahNames.nameAr(surahId)
        : SurahNames.nameEn(surahId);
  }

  String _coachSurahLabel(BuildContext context, int? surahId) {
    if (surahId == null) {
      return context.l10n.journeyFallbackSurah;
    }
    return '${context.l10n.surah} ${_coachSurahName(context, surahId)}';
  }

  String _coachAyahLabel(BuildContext context, SmartCoachRecommendation coach) {
    final start = coach.startAyah;
    final end = coach.endAyah;
    if (start == null) return '';
    if (end == null || end == start) {
      return context.l10n.journeyAyahLabel(start);
    }
    return context.l10n.journeyAyahsLabel(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final action = _action(context);

    return InkWell(
      onTap: () => context.push(action.$4),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: 0.14),
              primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: primary.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(action.$3, color: primary, size: 30),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.$1,
                    style: AppTypography.titleMedium.copyWith(
                      color: textColor,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    action.$2,
                    style: AppTypography.bodySmall.copyWith(
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              context.isArabic
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeEngagementSection extends StatelessWidget {
  const _HomeEngagementSection({required this.state, required this.isDark});

  final HomeLoaded state;
  final bool isDark;

  int _weeklyActivityCount() {
    final today = DateTime.now();
    var total = 0;
    for (var i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      total += state.activityCountsByDay[key] ?? 0;
    }
    return total;
  }

  XpLevel _currentLevel() {
    for (var i = XpConstants.levels.length - 1; i >= 0; i--) {
      if (state.totalXp >= XpConstants.levels[i].minXp) {
        return XpConstants.levels[i];
      }
    }
    return XpConstants.levels.first;
  }

  String _levelLabel(BuildContext context, XpLevel level) {
    final index = XpConstants.levels.indexOf(level);
    return switch (index) {
      0 => context.l10n.levelBeginner,
      1 => context.l10n.levelStudent,
      2 => context.l10n.levelHafez,
      3 => context.l10n.levelSheikh,
      4 => context.l10n.levelImam,
      _ => level.name,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final level = _currentLevel();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.bentoCard(
        isDark: isDark,
        accentGlow: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.homeEngagementTitle,
            style: AppTypography.titleMedium.copyWith(
              color: textColor,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<StreakCubit, StreakState>(
            builder: (context, streakState) {
              final streak = streakState is StreakLoaded
                  ? streakState.streak.currentStreak
                  : state.progress.streakDays;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _HomeEngagementTile(
                          icon: Icons.local_fire_department_rounded,
                          label: context.l10n.streakTerm,
                          value: '$streak',
                          color: AppColors.streakOrange,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _HomeEngagementTile(
                          icon: Icons.military_tech_rounded,
                          label: context.l10n.homeXpLevelLabel,
                          value: '${level.icon} ${_levelLabel(context, level)}',
                          color: AppColors.accentPurple,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeEngagementTile(
                          icon: Icons.today_rounded,
                          label: context.l10n.homeDueTodayLabel,
                          value: '${state.progress.reviewAyahs}',
                          color: AppColors.info,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _HomeEngagementTile(
                          icon: Icons.calendar_view_week_rounded,
                          label: context.l10n.homeWeeklyActivityLabel,
                          value: '${_weeklyActivityCount()}',
                          color: AppColors.primary,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeEngagementTile extends StatelessWidget {
  const _HomeEngagementTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: subTextColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HomeActivityHeatmapSection extends StatelessWidget {
  const _HomeActivityHeatmapSection({
    required this.state,
    required this.isDark,
  });

  final HomeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.homeActivityHeatmapTitle,
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ActivityHeatmap(
            activityCountsByDay: state.activityCountsByDay,
            startDate: state.activityStartDate,
          ),
        ],
      ),
    );
  }
}
