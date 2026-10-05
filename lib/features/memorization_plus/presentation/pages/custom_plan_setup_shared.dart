part of 'custom_plan_setup_page.dart';

class _PresetSelector extends StatelessWidget {
  const _PresetSelector({
    required this.isDark,
    required this.onSelect,
    this.activeName,
  });

  final bool isDark;

  /// Plan name of the preset currently applied, if any.
  final String? activeName;
  final void Function({
    required String name,
    required int newAyahs,
    required int days,
    required int minutes,
    required MemorizationDifficulty difficulty,
    int? startSurahId,
    int? endSurahId,
  })
  onSelect;

  @override
  Widget build(BuildContext context) {
    final presets = [
      (
        context.l10n.customPlanPresetLight,
        context.l10n.customPlanPresetLightDesc,
        Icons.spa_rounded,
        AppColors.success,
        context.l10n.customPlanPresetLightName,
        () => onSelect(
          name: context.l10n.customPlanPresetLightName,
          newAyahs: 3,
          days: 5,
          minutes: 20,
          difficulty: MemorizationDifficulty.easy,
        ),
      ),
      (
        context.l10n.customPlanPresetBalanced,
        context.l10n.customPlanPresetBalancedDesc,
        Icons.balance_rounded,
        AppColors.primary,
        context.l10n.customPlanPresetBalancedName,
        () => onSelect(
          name: context.l10n.customPlanPresetBalancedName,
          newAyahs: 5,
          days: 6,
          minutes: 30,
          difficulty: MemorizationDifficulty.moderate,
        ),
      ),
      (
        context.l10n.customPlanPresetIntensive,
        context.l10n.customPlanPresetIntensiveDesc,
        Icons.local_fire_department_rounded,
        Colors.deepOrange,
        context.l10n.customPlanPresetIntensiveName,
        () => onSelect(
          name: context.l10n.customPlanPresetIntensiveName,
          newAyahs: 10,
          days: 7,
          minutes: 50,
          difficulty: MemorizationDifficulty.challenging,
        ),
      ),
      (
        context.l10n.customPlanPresetJuzAmma,
        context.l10n.customPlanPresetJuzAmmaDesc,
        Icons.auto_stories_rounded,
        Colors.purple,
        context.l10n.customPlanPresetJuzAmmaName,
        () => onSelect(
          name: context.l10n.customPlanPresetJuzAmmaName,
          newAyahs: 3,
          days: 5,
          minutes: 20,
          difficulty: MemorizationDifficulty.easy,
          startSurahId: 114, // سورة الناس = بداية الحفظ (من)
          endSurahId: 78, // سورة النبأ = نهاية الحفظ (إلى)
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.bolt_rounded,
          title: context.l10n.customPlanQuickPresetTitle,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...presets.map(
          (preset) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InkWell(
              onTap: preset.$6,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                key: ValueKey('custom_plan_preset_${preset.$5}'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: preset.$4.withValues(alpha: isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: preset.$5 == activeName
                        ? preset.$4
                        : preset.$4.withValues(alpha: 0.22),
                    width: preset.$5 == activeName ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(preset.$3, color: preset.$4),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.$1,
                            style: AppTypography.titleMedium.copyWith(
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(preset.$2, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    if (preset.$5 == activeName)
                      Icon(Icons.check_circle_rounded, color: preset.$4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({
    required this.isDark,
    required this.ayahsPerDay,
    required this.daysPerWeek,
    required this.sessionMinutes,
    required this.difficulty,
    required this.startSurah,
    required this.endSurah,
  });

  final bool isDark;
  final int ayahsPerDay;
  final int daysPerWeek;
  final int sessionMinutes;
  final MemorizationDifficulty difficulty;
  final String startSurah;
  final String endSurah;

  @override
  Widget build(BuildContext context) {
    final difficultyLabel = switch (difficulty) {
      MemorizationDifficulty.easy => context.l10n.customPlanDifficultyEasy,
      MemorizationDifficulty.moderate =>
        context.l10n.customPlanDifficultyModerate,
      MemorizationDifficulty.challenging =>
        context.l10n.customPlanDifficultyChallenging,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.customPlanSummaryTitle,
            style: AppTypography.titleLarge.copyWith(fontFamily: 'Amiri'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(context.l10n.customPlanSummaryRange(startSurah, endSurah)),
          Text(
            context.l10n.customPlanSummaryLoad(
              ayahsPerDay,
              context.numText(ayahsPerDay),
              daysPerWeek,
              context.numText(daysPerWeek),
            ),
          ),
          Text(
            context.l10n.customPlanSummarySession(
              sessionMinutes,
              context.numText(sessionMinutes),
              difficultyLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.isDark,
  });
  final IconData icon;
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.tokens.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: context.tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.isDark,
    this.validator,
  });
  final TextEditingController controller;
  final String hintText;
  final bool isDark;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textDirection: TextDirection.rtl,
      style: AppTypography.bodyMedium.copyWith(
        color: context.tokens.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: context.tokens.textSecondary,
        ),
        filled: true,
        fillColor: context.tokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

class _DeletePlanDialog extends StatefulWidget {
  const _DeletePlanDialog({
    required this.confirmText,
    required this.title,
    required this.keepsText,
    required this.removesText,
    required this.instructionText,
    required this.cancelText,
    required this.actionText,
  });

  final String confirmText;
  final String title;
  final String keepsText;
  final String removesText;
  final String instructionText;
  final String cancelText;
  final String actionText;

  @override
  State<_DeletePlanDialog> createState() => _DeletePlanDialogState();
}

class _DeletePlanDialogState extends State<_DeletePlanDialog> {
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChecklistLine(
              icon: Icons.check_circle_rounded,
              color: AppColors.primary,
              text: widget.keepsText,
            ),
            const SizedBox(height: 10),
            _ChecklistLine(
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              text: widget.removesText,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.instructionText),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: widget.confirmText),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(widget.cancelText),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _confirmController.text.trim() == widget.confirmText
              ? () => Navigator.pop(context, true)
              : null,
          child: Text(widget.actionText),
        ),
      ],
    );
  }
}
