import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/seasons/season_calendar.dart';
import '../../../../core/services/hijri_date_adjustment.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../../core/utils/locale_numeric_input_formatter.dart';
import '../../domain/entities/khatmah_dedication.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_plan_template.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../khatmah_localizations.dart';
import '../khatmah_setup_prefill.dart';
import '../cubits/khatmah_setup_cubit.dart';
import '../widgets/khatmah_dedication_form.dart';

class KhatmahSetupPage extends StatefulWidget {
  const KhatmahSetupPage({
    super.key,
    this.cubit,
    this.prefill,
    this.ramadanInfo,
    this.now,
  });

  /// Season snapshot override (tests). When null it is resolved from the
  /// Ramadan experience flag and the user's Hijri adjustment.
  final RamadanInfo? ramadanInfo;

  /// Clock override (tests).
  final DateTime? now;

  final KhatmahSetupCubit? cubit;

  /// Choices carried over from a finished khatmah ("same settings").
  final KhatmahSetupPrefill? prefill;

  @override
  State<KhatmahSetupPage> createState() => _KhatmahSetupPageState();
}

class _KhatmahSetupPageState extends State<KhatmahSetupPage> {
  late final KhatmahSetupCubit _cubit;
  bool _createdOwnCubit = false;

  int _selectedPages = 4;
  final TextEditingController _customController = TextEditingController();
  KhatmahDedication _dedication = const KhatmahDedication();

  static const List<int> _presets = [2, 4, 10, 20];

  /// Duration presets (C7): a khatmah planned by days, e.g. Ramadan.
  static const List<int> _durationPresets = [30, 60, 90, 120];

  /// Set when the learner picked a duration; null when planning by pages.
  int? _selectedDays;

  /// Optional start page (C7); empty means page 1.
  final TextEditingController _startPageController = TextEditingController();
  String? _languageCode;

  /// Ramadan templates are offered only while this is non-null.
  RamadanInfo? _ramadan;
  RamadanKhatmahTemplate? _template;
  KhatmahTemplateParams? _templateParams;

  /// Series link carried from a finished khatmah (its next round).
  KhatmahSeasonLink? _prefillLink;

  static RamadanInfo? _resolveRamadan(DateTime now, RamadanInfo? override) {
    try {
      if (!getIt.isRegistered<ExperienceFlags>() ||
          !getIt<ExperienceFlags>().isEnabled(
            ExperienceFeature.seasonalRamadan,
          )) {
        return null;
      }
      if (override != null) return override;
      final adjustment = getIt.isRegistered<HijriDateAdjustment>()
          ? getIt<HijriDateAdjustment>().days
          : 0;
      return ramadanInfoAt(now, adjustmentDays: adjustment);
    } catch (error, stackTrace) {
      TaliaLogger.w('Ramadan khatmah templates unavailable', error, stackTrace);
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final info = _resolveRamadan(
      widget.now ?? DateTime.now(),
      widget.ramadanInfo,
    );
    if (info != null &&
        (info.phase == RamadanPhase.invite ||
            info.phase == RamadanPhase.ramadan ||
            info.phase == RamadanPhase.lastTen)) {
      _ramadan = info;
    }
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
    } else {
      try {
        _cubit = context.read<KhatmahSetupCubit>();
      } catch (_) {
        _cubit = getIt<KhatmahSetupCubit>();
        _createdOwnCubit = true;
      }
    }
    final prefill = widget.prefill;
    if (prefill != null) {
      _selectedPages = prefill.pagesPerDay;
      _selectedDays = prefill.targetDays;
      _prefillLink = prefill.seasonLink;
      if (prefill.targetDays == null &&
          !_presets.contains(prefill.pagesPerDay)) {
        _customController.text = '${prefill.pagesPerDay}';
      }
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _startPageController.dispose();
    if (_createdOwnCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_languageCode == languageCode) {
      return;
    }
    _languageCode = languageCode;
    for (final controller in [_customController, _startPageController]) {
      controller.value = controller.value.copyWith(
        text: context.digitText(controller.text),
        selection: TextSelection.collapsed(offset: controller.text.length),
      );
    }
  }

  void _onTemplateSelected(RamadanKhatmahTemplate template) {
    final info = _ramadan;
    if (info == null) return;
    final today = widget.now ?? DateTime.now();
    final params = paramsFor(template, info, today);
    setState(() {
      _template = template;
      _templateParams = params;
      _selectedDays = params.targetDays;
      _selectedPages = params.pagesPerDay;
      _customController.clear();
    });
  }

  void _clearTemplate() {
    _template = null;
    _templateParams = null;
  }

  void _onDurationSelected(int days) {
    setState(() {
      _clearTemplate();
      _selectedDays = days;
      _selectedPages = (KhatmahSchedulingEngine.totalPages / days).ceil();
      _customController.clear();
    });
  }

  void _onPresetSelected(int pages) {
    setState(() {
      _clearTemplate();
      _selectedDays = null;
      _selectedPages = pages;
      _customController.clear();
    });
  }

  void _onCustomChanged(String value) {
    final parsed = parseKhatmahPageInput(value);
    if (parsed != null &&
        parsed > 0 &&
        parsed <= KhatmahSchedulingEngine.totalPages) {
      setState(() {
        _clearTemplate();
        _selectedDays = null;
        _selectedPages = parsed;
      });
    }
  }

  /// Links the first of two Ramadan khatmahs to the month's last day, so the
  /// second is offered when it completes. A chosen template replaces a link
  /// carried from a finished khatmah.
  KhatmahSeasonLink? get _seasonLink {
    final template = _template;
    final last = _ramadan?.lastDay;
    if (template == null) return _prefillLink;
    if (template != RamadanKhatmahTemplate.twoInMonth || last == null) {
      return null;
    }
    return KhatmahSeasonLink(round: 1, rounds: 2, lastDay: last);
  }

  void _onSubmit() {
    _cubit.createPlan(
      portionsPerDay: _templateParams?.portionsPerDay ?? 1,
      seasonLink: _seasonLink,
      pagesPerDay: _selectedPages,
      dedication: _dedication,
      targetDays: _selectedDays,
      startPage: parseKhatmahPageInput(_startPageController.text) ?? 1,
      // Ramadan: one juz a day, ending on the juz boundary.
      wirdUnit:
          _templateParams?.wirdUnit ??
          (_selectedDays == 30 ? KhatmahWirdUnit.juz : KhatmahWirdUnit.pages),
    );
  }

  void _showAbandonExistingConfirmDialog(KhatmahSetupConflict conflict) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.khatmahEndCurrentConfirmTitle),
        content: Text(
          l10n.khatmahEndCurrentConfirmDescription(
            localizedKhatmahPlanTitle(context, conflict.existingPlan.title),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('khatmah_setup_abandon_confirm_button'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _cubit.abandonExistingPlan();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.khatmahEndPlanAction),
          ),
        ],
      ),
    );
  }

  String _prayerName(int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.prayerFajr,
      1 => l10n.prayerDhuhr,
      2 => l10n.prayerAsr,
      3 => l10n.prayerMaghrib,
      _ => l10n.prayerIsha,
    };
  }

  Widget _buildRamadanTemplates(BuildContext context) {
    final l10n = context.l10n;
    final info = _ramadan!;
    final today = widget.now ?? DateTime.now();
    final remaining = ramadanDaysRemaining(info, today);
    final labels = {
      RamadanKhatmahTemplate.oneInMonth: l10n.ramadanTemplateOne,
      RamadanKhatmahTemplate.twoInMonth: l10n.ramadanTemplateTwo,
      RamadanKhatmahTemplate.splitByPrayers: l10n.ramadanTemplateSplit,
    };
    final params = _templateParams;
    final startPage = (parseKhatmahPageInput(_startPageController.text) ?? 1)
        .clamp(1, KhatmahSchedulingEngine.totalPages);
    final portions = _template == RamadanKhatmahTemplate.splitByPrayers &&
            params != null
        ? () {
            final wird = ramadanDailyWird(params, startPage);
            return splitPagesIntoPortions(
              wird.startPage,
              wird.endPage,
              params.portionsPerDay,
            );
          }()
        : const <({int from, int to})>[];
    return Container(
      key: const Key('khatmah_setup_ramadan_templates'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry in labels.entries)
                ChoiceChip(
                  key: Key('khatmah_setup_ramadan_${entry.key.name}'),
                  label: Text(entry.value),
                  selected: _template == entry.key,
                  selectedColor: AppColors.gold.withValues(alpha: 0.25),
                  onSelected: (_) => _onTemplateSelected(entry.key),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.ramadanTemplateDays(remaining, context.numText(remaining)),
            style: AppTypography.bodySmall.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
          if (_template == RamadanKhatmahTemplate.twoInMonth)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.ramadanTemplateTwoHint,
                key: const Key('khatmah_setup_ramadan_two_hint'),
                style: AppTypography.bodySmall.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ),
          for (var i = 0; i < portions.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.ramadanPortion(
                  _prayerName(i),
                  context.numText(portions[i].from),
                  context.numText(portions[i].to),
                ),
                key: Key('khatmah_setup_ramadan_portion_$i'),
                style: AppTypography.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;
    final primary = context.tokens.accent;
    final cardBg = context.tokens.card;

    final estimatedDays =
        _selectedDays ??
        KhatmahSchedulingEngine.calculateDaysFromPages(
          KhatmahSchedulingEngine.totalPages,
          _selectedPages,
        );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = KhatmahSchedulingEngine.calculateEndDate(
      today,
      estimatedDays,
    );
    final dateStr =
        '${endDate.year}/${endDate.month.toString().padLeft(2, '0')}/${endDate.day.toString().padLeft(2, '0')}';

    final daysDisplay = context.numText(estimatedDays);
    final dateDisplay = context.digitText(dateStr);

    return BlocProvider<KhatmahSetupCubit>.value(
      value: _cubit,
      child: BlocConsumer<KhatmahSetupCubit, KhatmahSetupState>(
        listener: (context, state) {
          if (state is KhatmahSetupDone) {
            context.go(AppRoutes.khatmahDashboard);
          } else if (state is KhatmahSetupError) {
            context.showSnackBar(
              context.l10n.khatmahSetupSaveError,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          final isSaving = state is KhatmahSetupSaving;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                context.l10n.khatmahStartNewKhatmah,
                style: AppTypography.titleLarge,
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subtitle intro
                    Text(
                      context
                          .l10n
                          .khatmahChooseYourDailyReadingPaceToCompleteThe,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (state is KhatmahSetupConflict) ...[
                      Container(
                        key: const Key('khatmah_setup_existing_plan_conflict'),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.existingPlan.status == KhatmahStatus.paused
                                  ? l10n.khatmahExistingPausedPlan
                                  : l10n.khatmahExistingActivePlan,
                              style: AppTypography.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              localizedKhatmahPlanTitle(
                                context,
                                state.existingPlan.title,
                              ),
                              style: AppTypography.bodyMedium,
                            ),
                            if (state.errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                context.l10n.khatmahEndError,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                OutlinedButton(
                                  onPressed: state.isAbandoning
                                      ? null
                                      : () => context.go(
                                          AppRoutes.khatmahDashboard,
                                        ),
                                  child: Text(l10n.khatmahViewCurrentPlan),
                                ),
                                TextButton(
                                  key: const Key(
                                    'khatmah_setup_abandon_existing_button',
                                  ),
                                  onPressed: state.isAbandoning
                                      ? null
                                      : () => _showAbandonExistingConfirmDialog(
                                          state,
                                        ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                  child: Text(l10n.khatmahEndCurrentPlan),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    if (_ramadan != null) ...[
                      _buildRamadanTemplates(context),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Daily pages selector card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                TaliaIcons.reading,
                                color: primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  context.l10n.khatmahDailyPages,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Preset chips
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: _presets.map((pages) {
                              final isSelected =
                                  _selectedDays == null &&
                                  _selectedPages == pages &&
                                  _customController.text.isEmpty;
                              final pagesStr = context.numText(pages);
                              return ChoiceChip(
                                key: Key('khatmah_setup_preset_$pages'),
                                label: Text(
                                  context.l10n.khatmahPages(pages, pagesStr),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.gold.withValues(
                                  alpha: 0.25,
                                ),
                                labelStyle: AppTypography.labelMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.goldDark
                                      : context.tokens.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) => _onPresetSelected(pages),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Custom input
                          TextFormField(
                            key: const Key('khatmah_setup_custom_input'),
                            controller: _customController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp('[0-9٠-٩]'),
                              ),
                              LocaleNumericInputFormatter(
                                Localizations.localeOf(context).languageCode,
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText:
                                  context.l10n.khatmahOrCustomPagesPerDay,
                              hintText: context.l10n.khatmahEG5,
                              prefixIcon: const Icon(TaliaIcons.edit),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            onChanged: _onCustomChanged,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            context.l10n.khatmahOrChooseDuration,
                            style: AppTypography.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: _durationPresets.map((days) {
                              final daysStr = context.numText(days);
                              return ChoiceChip(
                                key: Key('khatmah_setup_duration_$days'),
                                label: Text(
                                  days == 30
                                      ? context.l10n.khatmahDurationRamadan
                                      : context.l10n.khatmahDurationDays(
                                          days,
                                          daysStr,
                                        ),
                                ),
                                selected: _selectedDays == days,
                                selectedColor: AppColors.gold.withValues(
                                  alpha: 0.25,
                                ),
                                onSelected: (_) => _onDurationSelected(days),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            key: const Key('khatmah_setup_start_page_input'),
                            controller: _startPageController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp('[0-9٠-٩]'),
                              ),
                              LocaleNumericInputFormatter(
                                Localizations.localeOf(context).languageCode,
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: context.l10n.khatmahStartFromPage,
                              helperText: context.l10n.khatmahStartFromPageHint,
                              helperMaxLines: 2,
                              prefixIcon: const Icon(TaliaIcons.bookmark),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Live calculation summary card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(
                          alpha: isDark ? 0.08 : 0.06,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          Column(
                            children: [
                              Text(
                                context.l10n.khatmahEstimatedDuration,
                                style: AppTypography.bodySmall.copyWith(
                                  color: context.tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.khatmahDays(
                                  estimatedDays,
                                  daysDisplay,
                                ),
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              Text(
                                context.l10n.khatmahExpectedCompletion,
                                style: AppTypography.bodySmall.copyWith(
                                  color: context.tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateDisplay,
                                style: AppTypography.titleMedium.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Optional Dedication Form
                    KhatmahDedicationForm(
                      initialDedication: _dedication,
                      onChanged: (dedication) {
                        setState(() {
                          _dedication = dedication;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit Button ("ابدأ الختمة")
                    FilledButton.icon(
                      key: const Key('khatmah_setup_submit_button'),
                      onPressed:
                          isSaving ||
                              (state is KhatmahSetupConflict &&
                                  state.isAbandoning)
                          ? null
                          : _onSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                      ),
                      icon: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(TaliaIcons.checkCircle),
                      label: Text(
                        context.l10n.khatmahStartKhatmah,
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
