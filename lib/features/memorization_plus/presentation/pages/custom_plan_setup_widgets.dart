part of 'custom_plan_setup_page.dart';

class _CustomPlanFormBody extends StatelessWidget {
  const _CustomPlanFormBody({
    required this.host,
    required this.planState,
    required this.isDark,
    required this.primaryColor,
  });

  final _CustomPlanSetupViewState host;
  final CustomPlanState planState;
  final bool isDark;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── App Bar ──
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: context.tokens.background,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: BoxDecoration(
                gradient: AppDecorations.memorizationHeader(isDark: isDark),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.xl,
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.customPlanTitle,
                        style: AppTypography.displaySmall.copyWith(
                          color: Colors.white,
                          fontFamily: 'Amiri',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.customPlanSubtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Form ──
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: host._formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PresetSelector(
                    isDark: isDark,
                    onSelect: host._applyPreset,
                    activeName: host._activePresetName,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Plan Name ──
                  _SectionTitle(
                    icon: TaliaIcons.edit,
                    title: context.l10n.customPlanName,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StyledTextField(
                    controller: host._nameController,
                    hintText: context.l10n.customPlanNameHint,
                    isDark: isDark,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.l10n.customPlanNameRequired;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Target User (Child/Adult) ──
                  _SectionTitle(
                    icon: TaliaIcons.people,
                    title: context.l10n.customPlanTargetUserTitle,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  host._buildTargetUserSelector(isDark),
                  if (host._targetUser == PlanTargetUser.child)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF0D5C53,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              TaliaIcons.info,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.customPlanChildFeaturesNote,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontFamily: 'Amiri',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Surah Range ──
                  _SectionTitle(
                    icon: TaliaIcons.mushaf,
                    title: context.l10n.customPlanSurahRange,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  host._buildSurahRangeSelector(isDark, primaryColor),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Daily Load ──
                  _SectionTitle(
                    icon: TaliaIcons.calendar,
                    title: context.l10n.customPlanDailyLoad,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  host._buildSliderCard(
                    title: context.l10n.customPlanNewAyahsPerDay,
                    value: host._newAyahsPerDay,
                    min: 1,
                    max: 10,
                    suffix: context.l10n.customPlanAyahUnit,
                    icon: TaliaIcons.reading,
                    color: Colors.amber,
                    isDark: isDark,
                    onChanged: (v) =>
                        host.applyPlanChange(() => host._newAyahsPerDay = v),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Schedule ──
                  _SectionTitle(
                    icon: TaliaIcons.calendarRange,
                    title: context.l10n.customPlanSchedule,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  host._buildSliderCard(
                    title: context.l10n.customPlanDaysPerWeek,
                    value: host._availableDays,
                    min: 1,
                    max: 7,
                    suffix: context.l10n.customPlanDayUnit,
                    icon: TaliaIcons.calendarRange,
                    color: Colors.blueAccent,
                    isDark: isDark,
                    onChanged: (v) =>
                        host.applyPlanChange(() => host._availableDays = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  host._buildSliderCard(
                    title: context.l10n.customPlanSessionDuration,
                    value: host._sessionMinutes,
                    min: 10,
                    max: 120,
                    suffix: context.l10n.customPlanMinuteUnit,
                    icon: TaliaIcons.timer,
                    color: Colors.teal,
                    isDark: isDark,
                    onChanged: (v) =>
                        host.applyPlanChange(() => host._sessionMinutes = v),
                    divisions: 11,
                  ),
                  if (host._newAyahsPerDay >
                      PlanSchedulePolicy.newAyahsFittingMinutes(
                        host._sessionMinutes,
                      ))
                    Padding(
                      key: const Key('custom_plan_minutes_limit_hint'),
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        context.l10n.customPlanMinutesLimitHint(
                          context.numText(host._sessionMinutes),
                          context.numText(
                            PlanSchedulePolicy.newAyahsFittingMinutes(
                              host._sessionMinutes,
                            ),
                          ),
                        ),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Difficulty ──
                  _SectionTitle(
                    icon: TaliaIcons.tune,
                    title: context.l10n.customPlanDifficulty,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  host._buildDifficultySelector(isDark, primaryColor),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Review Settings ──
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: _SectionTitle(
                      icon: TaliaIcons.replay,
                      title: context.l10n.customPlanAdvanced,
                      isDark: isDark,
                    ),
                    subtitle: Text(context.l10n.customPlanAdvancedSubtitle),
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      host._buildReviewSettings(isDark, primaryColor),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Estimated Duration ──
                  host._buildEstimatedDuration(isDark),

                  const SizedBox(height: AppSpacing.xl),

                  _PlanSummaryCard(
                    isDark: isDark,
                    ayahsPerDay: host._newAyahsPerDay,
                    daysPerWeek: host._availableDays,
                    sessionMinutes: host._sessionMinutes,
                    difficulty: host._difficulty,
                    // "من" = startSurahId (entry point), "إلى" = endSurahId (exit point)
                    startSurah: host._startSurahId < host._surahNames.length
                        ? host._surahNames[host._startSurahId]
                        : '${context.l10n.surah} ${host._startSurahId}',
                    endSurah: host._endSurahId < host._surahNames.length
                        ? host._surahNames[host._endSurahId]
                        : '${context.l10n.surah} ${host._endSurahId}',
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Save Button ──
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: host._save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(TaliaIcons.save),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.customPlanSaveAndStart,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Delete existing plan
                  if (planState is CustomPlanLoaded) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      onPressed: () =>
                          host._showDeletePlanConfirmation(context),
                      icon: const Icon(
                        TaliaIcons.delete,
                        color: AppColors.error,
                      ),
                      label: Text(
                        context.l10n.customPlanDeleteCurrent,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
