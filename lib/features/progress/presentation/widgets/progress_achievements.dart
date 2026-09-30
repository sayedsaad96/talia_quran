part of '../pages/progress_page.dart';

class _AchievementsCategorized extends StatefulWidget {
  const _AchievementsCategorized({
    required this.achievements,
    required this.isDark,
  });
  final List<Achievement> achievements;
  final bool isDark;

  @override
  State<_AchievementsCategorized> createState() =>
      _AchievementsCategorizedState();
}

class _AchievementsCategorizedState extends State<_AchievementsCategorized> {
  int _selectedTab = 0;

  static const _categories = [
    null, // All
    AchievementCategory.reading,
    AchievementCategory.memorization,
    AchievementCategory.streak,
  ];

  List<Achievement> get _filtered {
    final cat = _categories[_selectedTab];
    if (cat == null) return widget.achievements;
    return widget.achievements.where((a) => a.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = context.tokens.accent;

    final tabLabels = [
      context.l10n.all,
      context.l10n.reading,
      context.l10n.memorization,
      context.l10n.streakTerm,
    ];

    return Column(
      children: [
        // Tab bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(tabLabels.length, (i) {
              final selected = _selectedTab == i;
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  end: i < tabLabels.length - 1 ? 8.0 : 0,
                ),
                child: Semantics(
                  button: true,
                  selected: selected,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? primary
                            : primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        tabLabels[i],
                        style: AppTypography.labelMedium.copyWith(
                          color: selected ? Colors.white : primary,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Achievement grid
        if (_filtered.isEmpty)
          SizedBox(
            height: 220,
            child: EmptyStateWidget(
              message: context.l10n.emptyState,
              icon: Icons.emoji_events_outlined,
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              // Fixed height that grows with the user's text scale, so
              // two-line titles never clip.
              mainAxisExtent: MediaQuery.textScalerOf(context).scale(150),
            ),
            itemCount: _filtered.length,
            itemBuilder: (context, i) =>
                _AchievementTile(achievement: _filtered[i], isDark: isDark),
          ),
      ],
    );
  }
}

// ─── Achievement Tile ─────────────────────────────────────────────────────────

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.isDark});
  final Achievement achievement;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final primary = context.tokens.accent;
    final surface = context.tokens.card;
    final border = context.tokens.divider;
    final hintColor = context.tokens.textHint;
    final title = context.localizedAchievementTitle(achievement);

    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: () => _showAchievementDetailSheet(context, achievement, isDark),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: unlocked ? primary.withValues(alpha: 0.08) : surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: unlocked ? primary.withValues(alpha: 0.25) : border,
              width: unlocked ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Expressive Image / Shape Badge
              _AchievementBadgeShape(
                achievement: achievement,
                isDark: isDark,
                isUnlocked: unlocked,
                size: 48,
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: unlocked ? primary : hintColor,
                  fontWeight: unlocked ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Progress bar or lock
              if (unlocked)
                Icon(Icons.check_circle_rounded, size: 14, color: primary)
              else ...[
                // Mini progress bar
                SizedBox(
                  width: 50,
                  child: LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 3,
                    percent: achievement.progressPercent,
                    progressColor: primary.withValues(alpha: 0.5),
                    backgroundColor: primary.withValues(alpha: 0.08),
                    barRadius: const Radius.circular(4),
                    animation: true,
                    animationDuration: 400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.countOfTotal(
                    achievement.currentValue,
                    achievement.targetValue,
                  ),
                  style: AppTypography.labelSmall.copyWith(color: hintColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Achievement Detail Sheet ─────────────────────────────────────────────────

void _showAchievementDetailSheet(
  BuildContext context,
  Achievement achievement,
  bool isDark,
) {
  final primary = context.tokens.accent;
  final surface = context.tokens.card;
  final title = context.localizedAchievementTitle(achievement);
  final description = context.localizedAchievementDescription(achievement);
  final textPrimary = context.tokens.textPrimary;
  final textSecondary = context.tokens.textSecondary;

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (sheetContext) => SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.tokens.divider,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AchievementBadgeShape(
              achievement: achievement,
              isDark: isDark,
              isUnlocked: achievement.isUnlocked,
              size: 96,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(color: textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Progress bar
            LinearPercentIndicator(
              lineHeight: 8,
              percent: achievement.progressPercent,
              progressColor: achievement.isUnlocked
                  ? AppColors.success
                  : primary,
              backgroundColor: primary.withValues(alpha: 0.1),
              barRadius: const Radius.circular(4),
              animation: true,
              animationDuration: 500,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.countOfTotal(
                achievement.currentValue,
                achievement.targetValue,
              ),
              style: AppTypography.labelMedium.copyWith(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (achievement.isUnlocked) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.achieved,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final data = SocialShareData.achievement(
                      achievement: achievement,
                      localizedTitle: title,
                      localizedDesc: description,
                      userName: _profileDisplayName(context),
                    );
                    Navigator.of(sheetContext).pop();
                    SocialShareSheet.show(context, data);
                  },
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(context.l10n.shareAchievement),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    ),
  );
}

// ─── Expressive Achievement Shapes ────────────────────────────────────────────

/// Medal tier per achievement: 0 bronze, 1 silver, 2 gold, 3 diamond,
/// 4 legendary. Keyed by id because targets mix units (pages, ayahs,
/// surahs, juz, days) and cannot be compared on one scale.
int _achievementRank(String id) {
  return switch (id) {
    'first_page' || 'ten_pages' || 'fifty_pages' => 0,
    'juz_read' => 1,
    'five_juz_read' => 2,
    'half_quran_read' => 3,
    'full_quran_read' => 4,
    'first_ayah' || 'ten_ayahs' => 0,
    'fifty_ayahs' || 'hundred_ayahs' || 'first_surah' => 1,
    'five_surahs' || 'ten_surahs' || 'juz_amma' || 'one_juz_memorized' => 2,
    'five_juz_memorized' || 'ten_juz_memorized' || 'half_quran_memorized' => 3,
    'full_quran_memorized' => 4,
    'three_day_streak' || 'week_streak' => 0,
    'two_week_streak' => 1,
    'month_streak' => 2,
    'ninety_day_streak' => 3,
    'year_streak' => 4,
    _ => 0,
  };
}

class _AchievementBadgeShape extends StatelessWidget {
  const _AchievementBadgeShape({
    required this.achievement,
    required this.isDark,
    required this.isUnlocked,
    required this.size,
  });

  final Achievement achievement;
  final bool isDark;
  final bool isUnlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Map IDs to specific icons
    IconData iconData = Icons.star_rounded;
    switch (achievement.id) {
      // Reading
      case 'first_page':
        iconData = Icons.menu_book_rounded;
        break;
      case 'ten_pages':
        iconData = Icons.import_contacts_rounded;
        break;
      case 'fifty_pages':
        iconData = Icons.auto_stories_rounded;
        break;
      case 'juz_read':
        iconData = Icons.chrome_reader_mode_rounded;
        break;
      case 'five_juz_read':
        iconData = Icons.library_books_rounded;
        break;
      case 'half_quran_read':
        iconData = Icons.emoji_events_rounded;
        break;
      case 'full_quran_read':
        iconData = Icons.diamond_rounded;
        break;

      // Memorization
      case 'first_ayah':
        iconData = Icons.star_outline_rounded;
        break;
      case 'ten_ayahs':
        iconData = Icons.star_half_rounded;
        break;
      case 'fifty_ayahs':
        iconData = Icons.star_rounded;
        break;
      case 'hundred_ayahs':
        iconData = Icons.stars_rounded;
        break;
      case 'first_surah':
        iconData = Icons.bookmark_added_rounded;
        break;
      case 'five_surahs':
        iconData = Icons.collections_bookmark_rounded;
        break;
      case 'ten_surahs':
        iconData = Icons.workspace_premium_rounded;
        break;
      case 'juz_amma':
        iconData = Icons.mosque_rounded;
        break;
      case 'one_juz_memorized':
        iconData = Icons.verified_rounded;
        break;
      case 'five_juz_memorized':
        iconData = Icons.military_tech_rounded;
        break;
      case 'ten_juz_memorized':
        iconData = Icons.shield_rounded;
        break;
      case 'half_quran_memorized':
        iconData = Icons.military_tech_rounded;
        break;
      case 'full_quran_memorized':
        iconData = Icons.diamond_rounded;
        break;

      // Streak
      case 'three_day_streak':
        iconData = Icons.local_fire_department_rounded;
        break;
      case 'week_streak':
        iconData = Icons.whatshot_rounded;
        break;
      case 'two_week_streak':
        iconData = Icons.bolt_rounded;
        break;
      case 'month_streak':
        iconData = Icons.offline_bolt_rounded;
        break;
      case 'ninety_day_streak':
        iconData = Icons.auto_awesome_rounded;
        break;
      case 'year_streak':
        iconData = Icons.workspace_premium_rounded;
        break;
    }

    final rank = _achievementRank(achievement.id);

    final List<Color> gradientColors;
    final Color glowColor;

    if (!isUnlocked) {
      gradientColors = isDark
          ? AchievementTierPalette.lockedDark
          : AchievementTierPalette.lockedLight;
      glowColor = Colors.transparent;
    } else {
      final tier = AchievementTierPalette.forRank(rank);
      gradientColors = tier.gradient;
      glowColor = tier.glow;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.4),
              blurRadius: size * 0.3,
              spreadRadius: size * 0.05,
              offset: const Offset(0, 2),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.05),
          ),
        ],
        border: Border.all(
          color: isUnlocked
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          width: size * 0.04,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: size * 0.55,
          color: isUnlocked
              ? Colors.white
              : (isDark ? Colors.white24 : Colors.black26),
        ),
      ),
    );
  }
}

// ─── Smart Memorization Progress Card ─────────────────────────────────────────
