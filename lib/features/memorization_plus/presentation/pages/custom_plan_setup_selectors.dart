part of 'custom_plan_setup_page.dart';

mixin _CustomPlanSelectors on _CustomPlanSetupController {
  Widget _buildTargetUserSelector(bool isDark) {
    final items = [
      (
        PlanTargetUser.adult,
        context.l10n.customPlanAdult,
        TaliaIcons.person,
        AppColors.primary,
      ),
      (
        PlanTargetUser.child,
        context.l10n.customPlanChild,
        TaliaIcons.child,
        AppColors.primary,
      ),
    ];

    return Row(
      children: items.map((item) {
        final isSelected = _targetUser == item.$1;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: () => unawaited(_selectTarget(item.$1)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? item.$4.withValues(alpha: 0.15)
                    : context.tokens.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: isSelected
                      ? item.$4
                      : isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(item.$3, color: item.$4, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    item.$2,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? item.$4
                          : context.tokens.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySelector(bool isDark, Color primary) {
    final items = [
      (
        MemorizationDifficulty.easy,
        context.l10n.customPlanDifficultyEasy,
        TaliaIcons.smile,
        AppColors.success,
      ),
      (
        MemorizationDifficulty.moderate,
        context.l10n.customPlanDifficultyModerate,
        TaliaIcons.meh,
        Colors.amber,
      ),
      (
        MemorizationDifficulty.challenging,
        context.l10n.customPlanDifficultyChallenging,
        TaliaIcons.frown,
        AppColors.error,
      ),
    ];

    return Row(
      children: items.map((item) {
        final isSelected = _difficulty == item.$1;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: () => setState(() => _difficulty = item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? item.$4.withValues(alpha: 0.15)
                    : context.tokens.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: isSelected
                      ? item.$4
                      : isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(item.$3, color: item.$4, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    item.$2,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? item.$4
                          : context.tokens.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewSettings(bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          // Near revision toggle
          _buildToggleRow(
            title: context.l10n.customPlanNearRevision,
            subtitle: context.l10n.customPlanNearRevisionSubtitle,
            value: _enableNearRevision,
            icon: TaliaIcons.update,
            color: Colors.blueAccent,
            isDark: isDark,
            onChanged: (v) => setState(() => _enableNearRevision = v),
          ),
          if (_enableNearRevision) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildMiniSlider(
              label: context.l10n.customPlanNearRevisionCount,
              value: _nearRevisionCount,
              min: 1,
              max: 15,
              isDark: isDark,
              color: Colors.blueAccent,
              onChanged: (v) => setState(() => _nearRevisionCount = v),
            ),
          ],
          Divider(
            height: 24,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          // Far revision toggle
          _buildToggleRow(
            title: context.l10n.customPlanFarRevision,
            subtitle: context.l10n.customPlanFarRevisionSubtitle,
            value: _enableFarRevision,
            icon: TaliaIcons.history,
            color: Colors.deepPurple,
            isDark: isDark,
            onChanged: (v) => setState(() => _enableFarRevision = v),
          ),
          if (_enableFarRevision) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildMiniSlider(
              label: context.l10n.customPlanFarRevisionCount,
              value: _farRevisionCount,
              min: 1,
              max: 10,
              isDark: isDark,
              color: Colors.deepPurple,
              onChanged: (v) => setState(() => _farRevisionCount = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, activeThumbColor: color, onChanged: onChanged),
      ],
    );
  }

  Widget _buildMiniSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required bool isDark,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        const SizedBox(width: 30),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ),
        Text(
          context.numText(value),
          style: AppTypography.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedDuration(bool isDark) {
    // Exact ayah totals from the loaded surah table (works in both
    // directions — a Juz Amma plan 114→78 is measured identically).
    final lo = _startSurahId <= _endSurahId ? _startSurahId : _endSurahId;
    final hi = _startSurahId <= _endSurahId ? _endSurahId : _startSurahId;
    var totalAyahsEstimate = 0;
    for (var surahId = lo; surahId <= hi; surahId++) {
      totalAyahsEstimate += _ayahCountForSurah(surahId);
    }
    final totalSurahs = hi - lo + 1;
    final sessionsPerWeek = _availableDays;
    // The session length caps new ayahs (PlanSchedulePolicy), so the
    // estimate uses what actually fits, not the requested number.
    final fitting = PlanSchedulePolicy.newAyahsFittingMinutes(_sessionMinutes);
    final ayahsPerSession = _newAyahsPerDay < fitting
        ? _newAyahsPerDay
        : fitting;
    final totalSessions = (totalAyahsEstimate / ayahsPerSession).ceil();
    final weeks = (totalSessions / sessionsPerWeek).ceil();
    final months = (weeks / 4.3).ceil();

    String durationText;
    if (months > 12) {
      final years = (months / 12.0);
      durationText = context.l10n.customPlanApproxYears(
        context.digitText(years.toStringAsFixed(1)),
      );
    } else if (months > 1) {
      durationText = context.l10n.customPlanApproxMonths(
        LocaleNumberFormatter.format(
          (months).toString(),
          context.l10n.localeName,
        ),
      );
    } else {
      durationText = context.l10n.customPlanApproxWeeks(
        weeks,
        context.numText(weeks),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withValues(alpha: isDark ? 0.3 : 0.1),
            Colors.blue.withValues(alpha: isDark ? 0.2 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              TaliaIcons.progress,
              color: Colors.deepPurple,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.customPlanEstimatedDuration,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  durationText,
                  style: AppTypography.titleLarge.copyWith(
                    color: context.tokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  context.l10n.customPlanEstimatedScope(
                    totalSurahs,
                    context.numText(totalSurahs),
                    totalAyahsEstimate,
                    context.numText(totalAyahsEstimate),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _selectTarget(PlanTargetUser target) async {
    if (target == _targetUser) return;
    if (target != PlanTargetUser.child) {
      setState(() => _targetUser = target);
      return;
    }
    final repository = getIt<MemorizationPlusRepository>();
    final profile = (await repository.getMemorizationProfile()).fold(
      (_) => null,
      (profile) => profile,
    );
    if (!mounted) return;
    if (profile?.isAdult == true) {
      final l10n = context.l10n;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.customPlanChildSwitchTitle),
          content: Text(l10n.customPlanChildSwitchBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('custom_plan_child_switch_confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.customPlanChildSwitchConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final result = await repository.resetMemorizationIdentity();
      if (!mounted) return;
      final failure = result.fold((failure) => failure, (_) => null);
      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.localizedCubitMessage(failure.message)),
          ),
        );
        return;
      }
      getIt<MemorizationPathResolver>().notifyChanged();
    }
    if (!mounted) return;
    context.go('${AppRoutes.memorizationPlus}?preferred=kids&setup=kids');
  }
}
