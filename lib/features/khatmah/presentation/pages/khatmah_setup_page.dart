import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../domain/entities/khatmah_dedication.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../cubits/khatmah_setup_cubit.dart';
import '../widgets/khatmah_dedication_form.dart';

class KhatmahSetupPage extends StatefulWidget {
  const KhatmahSetupPage({super.key, this.cubit});

  final KhatmahSetupCubit? cubit;

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

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _customController.dispose();
    if (_createdOwnCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _onPresetSelected(int pages) {
    setState(() {
      _selectedPages = pages;
      _customController.clear();
    });
  }

  void _onCustomChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null &&
        parsed > 0 &&
        parsed <= KhatmahSchedulingEngine.totalPages) {
      setState(() {
        _selectedPages = parsed;
      });
    }
  }

  void _onSubmit() {
    _cubit.createPlan(pagesPerDay: _selectedPages, dedication: _dedication);
  }

  void _showAbandonExistingConfirmDialog(KhatmahSetupConflict conflict) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.khatmahEndCurrentConfirmTitle),
        content: Text(
          l10n.khatmahEndCurrentConfirmDescription(conflict.existingPlan.title),
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isArabic = context.isArabic;
    final l10n = context.l10n;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    final estimatedDays = KhatmahSchedulingEngine.calculateDaysFromPages(
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

    final daysDisplay = isArabic
        ? MushafHizbHelper.toArabicNumber(estimatedDays)
        : estimatedDays.toString();
    final dateDisplay = isArabic ? _toArabicDigits(dateStr) : dateStr;

    return BlocProvider<KhatmahSetupCubit>.value(
      value: _cubit,
      child: BlocConsumer<KhatmahSetupCubit, KhatmahSetupState>(
        listener: (context, state) {
          if (state is KhatmahSetupDone) {
            context.go(AppRoutes.khatmahDashboard);
          } else if (state is KhatmahSetupError) {
            context.showSnackBar(state.message, isError: true);
          }
        },
        builder: (context, state) {
          final isSaving = state is KhatmahSetupSaving;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                isArabic ? 'بدء ختمة جديدة' : 'Start New Khatmah',
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
                      isArabic
                          ? 'اختر خطتك اليومية المناسبة لقراءة القرآن الكريم بهدوء وسكينة'
                          : 'Choose your daily reading pace to complete the Quran with serenity.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
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
                              state.existingPlan.title,
                              style: AppTypography.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      context.go(AppRoutes.khatmahDashboard),
                                  child: Text(l10n.khatmahViewCurrentPlan),
                                ),
                                TextButton(
                                  key: const Key(
                                    'khatmah_setup_abandon_existing_button',
                                  ),
                                  onPressed: () =>
                                      _showAbandonExistingConfirmDialog(state),
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
                                Icons.auto_stories_rounded,
                                color: primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                isArabic ? 'الصفحات اليومية' : 'Daily Pages',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
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
                                  _selectedPages == pages &&
                                  _customController.text.isEmpty;
                              final pagesStr = isArabic
                                  ? MushafHizbHelper.toArabicNumber(pages)
                                  : pages.toString();
                              return ChoiceChip(
                                key: Key('khatmah_setup_preset_$pages'),
                                label: Text(
                                  isArabic ? '$pagesStr صفحات' : '$pages pages',
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.gold.withValues(
                                  alpha: 0.25,
                                ),
                                labelStyle: AppTypography.labelMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.goldDark
                                      : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
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
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: isArabic
                                  ? 'أو عدد مخصص يومياً'
                                  : 'Or custom pages per day',
                              hintText: isArabic ? 'مثال: 5' : 'e.g. 5',
                              prefixIcon: const Icon(Icons.edit_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            onChanged: _onCustomChanged,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                isArabic
                                    ? 'المدة التقديرية'
                                    : 'Estimated Duration',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isArabic
                                    ? '$daysDisplay يوماً'
                                    : '$daysDisplay days',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 36,
                            width: 1,
                            color: AppColors.gold.withValues(alpha: 0.2),
                          ),
                          Column(
                            children: [
                              Text(
                                isArabic
                                    ? 'موعد الختام المتوقع'
                                    : 'Expected Completion',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
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
                      onPressed: isSaving ? null : _onSubmit,
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
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        isArabic ? 'ابدأ الختمة' : 'Start Khatmah',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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

  static String _toArabicDigits(String input) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.replaceAllMapped(
      RegExp(r'\d'),
      (m) => digits[int.parse(m.group(0)!)],
    );
  }
}
