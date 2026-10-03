import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/services/plan_schedule_policy.dart';
import '../cubits/custom_plan_cubit.dart';


const List<int> _standardSurahAyahCounts = [
  0,
  7,
  286,
  200,
  176,
  120,
  165,
  206,
  75,
  129,
  109,
  123,
  111,
  43,
  52,
  99,
  128,
  111,
  110,
  98,
  135,
  112,
  78,
  118,
  64,
  77,
  227,
  93,
  88,
  69,
  60,
  34,
  30,
  73,
  54,
  45,
  83,
  182,
  88,
  75,
  85,
  54,
  53,
  89,
  59,
  37,
  35,
  38,
  29,
  18,
  45,
  60,
  49,
  62,
  55,
  78,
  96,
  29,
  22,
  24,
  13,
  14,
  11,
  11,
  18,
  12,
  12,
  30,
  52,
  52,
  44,
  28,
  28,
  20,
  56,
  40,
  31,
  50,
  40,
  46,
  42,
  29,
  19,
  36,
  25,
  22,
  17,
  19,
  26,
  30,
  20,
  15,
  21,
  11,
  8,
  8,
  19,
  5,
  8,
  8,
  11,
  11,
  8,
  3,
  9,
  5,
  4,
  7,
  3,
  6,
  3,
  5,
  4,
  5,
  6,
];

class CustomPlanSetupPage extends StatelessWidget {
  const CustomPlanSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CustomPlanCubit>()..load(),
      child: const _CustomPlanSetupView(),
    );
  }
}

class _CustomPlanSetupView extends StatefulWidget {
  const _CustomPlanSetupView();

  @override
  State<_CustomPlanSetupView> createState() => _CustomPlanSetupViewState();
}

class _CustomPlanSetupViewState extends State<_CustomPlanSetupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startAyahController = TextEditingController(text: '1');

  int _startSurahId = 1;
  int _endSurahId = 114;
  int _startAyah = 1;
  int _newAyahsPerDay = 3;

  /// The quick preset last applied; it stays highlighted while its values
  /// are unchanged.
  ({String name, int newAyahs, int days, int minutes})? _appliedPreset;

  String? get _activePresetName {
    final preset = _appliedPreset;
    if (preset == null ||
        preset.newAyahs != _newAyahsPerDay ||
        preset.days != _availableDays ||
        preset.minutes != _sessionMinutes) {
      return null;
    }
    return preset.name;
  }

  int _availableDays = 7;
  int _sessionMinutes = 30;
  MemorizationDifficulty _difficulty = MemorizationDifficulty.moderate;
  bool _enableNearRevision = true;
  bool _enableFarRevision = true;
  int _nearRevisionCount = 5;
  int _farRevisionCount = 3;
  PlanTargetUser _targetUser = PlanTargetUser.adult;
  bool _didLoadSurahNames = false;

  /// Surah names loaded from data layer (1-indexed, index 0 is placeholder)
  List<String> _surahNames = [''];
  List<int> _surahAyahCounts = _standardSurahAyahCounts;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final formatted = context.digitText(
      LocaleNumberFormatter.western(_startAyahController.text),
    );
    if (_startAyahController.text != formatted) {
      _startAyahController.value = _startAyahController.value.copyWith(
        text: formatted,
      );
    }
    if (_didLoadSurahNames) return;
    _didLoadSurahNames = true;
    _loadSurahNames();
  }

  Future<void> _loadSurahNames() async {
    try {
      final surahsResult = await getIt<QuranRepository>().getSurahs();
      surahsResult.fold(
        (failure) {
          _loadFallbackSurahNames();
        },
        (surahs) {
          if (mounted) {
            final isArabic = context.isArabic;
            setState(() {
              _surahNames = [
                '',
                ...surahs.map((s) => isArabic ? s.nameAr : s.nameEn),
              ];
              _surahAyahCounts = [0, ...surahs.map((s) => s.ayahCount)];
              _clampStartAyahForSurah();
            });
          }
        },
      );
    } catch (_) {
      _loadFallbackSurahNames();
    }
  }

  void _loadFallbackSurahNames() {
    if (mounted) {
      final surahLabel = context.l10n.surah;
      setState(() {
        _surahNames = List.generate(115, (i) => i == 0 ? '' : '$surahLabel $i');
        _surahAyahCounts = _standardSurahAyahCounts;
        _clampStartAyahForSurah();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startAyahController.dispose();
    super.dispose();
  }

  void _populateFromExisting(CustomMemorizationPlan plan) {
    _nameController.text = plan.name;
    _startSurahId = plan.startSurahId;
    _endSurahId = plan.endSurahId;
    _startAyah = plan.startAyah;
    _startAyahController.text = context.numText(_startAyah);
    _newAyahsPerDay = plan.newAyahsPerDay;
    _availableDays = plan.availableDaysPerWeek;
    _sessionMinutes = plan.sessionMinutes;
    _difficulty = plan.difficulty;
    _enableNearRevision = plan.enableNearRevision;
    _enableFarRevision = plan.enableFarRevision;
    _nearRevisionCount = plan.nearRevisionCount;
    _farRevisionCount = plan.farRevisionCount;
    _targetUser = plan.targetUser;
  }

  void _applyPreset({
    required String name,
    required int newAyahs,
    required int days,
    required int minutes,
    required MemorizationDifficulty difficulty,
    int? startSurahId,
    int? endSurahId,
  }) {
    setState(() {
      _appliedPreset = (
        name: name,
        newAyahs: newAyahs,
        days: days,
        minutes: minutes,
      );
      _nameController.text = name;
      _newAyahsPerDay = newAyahs;
      _availableDays = days;
      _sessionMinutes = minutes;
      _difficulty = difficulty;
      if (startSurahId != null) _startSurahId = startSurahId;
      if (endSurahId != null) _endSurahId = endSurahId;
      _clampStartAyahForSurah();
    });
  }

  int _ayahCountForSurah(int surahId) {
    if (surahId >= 1 && surahId < _surahAyahCounts.length) {
      return _surahAyahCounts[surahId];
    }
    return 286;
  }

  void _setStartSurah(int surahId) {
    _startSurahId = surahId;
    // Entry/exit model (no forced ordering): "من" is where memorization
    // starts, "إلى" is where it ends — either direction is legal (a Juz Amma
    // plan runs 114 → 78). The direction hint below makes the flow explicit.
    _clampStartAyahForSurah();
  }

  void _clampStartAyahForSurah() {
    final maxAyah = _ayahCountForSurah(_startSurahId);
    if (_startAyah > maxAyah) {
      _startAyah = maxAyah;
      _startAyahController.text = context.numText(_startAyah);
    }
    if (_startAyah < 1) {
      _startAyah = 1;
      _startAyahController.text = context.numText(1);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _startAyah =
        int.tryParse(
          LocaleNumberFormatter.western(_startAyahController.text.trim()),
        ) ??
        _startAyah;

    final plan = CustomMemorizationPlan(
      name: _nameController.text.trim(),
      startSurahId: _startSurahId,
      endSurahId: _endSurahId,
      startAyah: _startAyah,
      newAyahsPerDay: _newAyahsPerDay,
      availableDaysPerWeek: _availableDays,
      sessionMinutes: _sessionMinutes,
      difficulty: _difficulty,
      enableNearRevision: _enableNearRevision,
      enableFarRevision: _enableFarRevision,
      nearRevisionCount: _nearRevisionCount,
      farRevisionCount: _farRevisionCount,
      createdAt: DateTime.now(),
      targetUser: _targetUser,
    );

    context.read<CustomPlanCubit>().savePlan(plan);
  }

  Future<void> _goToSavedPlan(
    BuildContext context,
    CustomMemorizationPlan plan,
  ) async {
    final resolver = MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    );
    final destination = plan.targetUser == PlanTargetUser.child
        ? await resolver.childOnboardingLocation()
        : await resolver.adultEntryLocation();
    if (!context.mounted) return;
    context.go(destination);
  }

  Future<void> _showDeletePlanConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DeletePlanDialog(
        confirmText: context.l10n.customPlanDeleteConfirmPhrase,
        title: context.l10n.customPlanDeleteTitle,
        keepsText: context.l10n.customPlanDeleteKeeps,
        removesText: context.l10n.customPlanDeleteRemoves,
        instructionText: context.l10n.customPlanDeleteInstruction,
        cancelText: context.l10n.cancel,
        actionText: context.l10n.customPlanDeleteAction,
      ),
    );

    if (confirmed == true && context.mounted) {
      unawaited(context.read<CustomPlanCubit>().deletePlan());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: context.tokens.background,
      body: BlocConsumer<CustomPlanCubit, CustomPlanState>(
        listener: (context, state) {
          if (state is CustomPlanSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.customPlanSaved),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            );
            // Navigate directly into the freshly saved plan (session/journey)
            // instead of dropping the user back on the hub.
            _goToSavedPlan(context, state.plan);
          } else if (state is CustomPlanLoaded) {
            _populateFromExisting(state.plan);
          }
        },
        builder: (context, state) {
          if (state is CustomPlanLoading) {
            return const Center(child: CircularProgressIndicator());
          }

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
                      gradient: AppDecorations.memorizationHeader(
                        isDark: isDark,
                      ),
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
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PresetSelector(
                          isDark: isDark,
                          onSelect: _applyPreset,
                          activeName: _activePresetName,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Plan Name ──
                        _SectionTitle(
                          icon: Icons.edit_rounded,
                          title: context.l10n.customPlanName,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _StyledTextField(
                          controller: _nameController,
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
                          icon: Icons.people_alt_rounded,
                          title: context.l10n.customPlanTargetUserTitle,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTargetUserSelector(isDark),
                        if (_targetUser == PlanTargetUser.child)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0D5C53,
                                ).withValues(alpha: 0.1),
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
                                    Icons.info_outline_rounded,
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
                          icon: Icons.menu_book_rounded,
                          title: context.l10n.customPlanSurahRange,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSurahRangeSelector(isDark, primaryColor),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Daily Load ──
                        _SectionTitle(
                          icon: Icons.today_rounded,
                          title: context.l10n.customPlanDailyLoad,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSliderCard(
                          title: context.l10n.customPlanNewAyahsPerDay,
                          value: _newAyahsPerDay,
                          min: 1,
                          max: 10,
                          suffix: context.l10n.customPlanAyahUnit,
                          icon: Icons.auto_stories_rounded,
                          color: Colors.amber,
                          isDark: isDark,
                          onChanged: (v) => setState(() => _newAyahsPerDay = v),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // ── Schedule ──
                        _SectionTitle(
                          icon: Icons.calendar_month_rounded,
                          title: context.l10n.customPlanSchedule,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSliderCard(
                          title: context.l10n.customPlanDaysPerWeek,
                          value: _availableDays,
                          min: 1,
                          max: 7,
                          suffix: context.l10n.customPlanDayUnit,
                          icon: Icons.date_range_rounded,
                          color: Colors.blueAccent,
                          isDark: isDark,
                          onChanged: (v) => setState(() => _availableDays = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSliderCard(
                          title: context.l10n.customPlanSessionDuration,
                          value: _sessionMinutes,
                          min: 10,
                          max: 120,
                          suffix: context.l10n.customPlanMinuteUnit,
                          icon: Icons.timer_rounded,
                          color: Colors.teal,
                          isDark: isDark,
                          onChanged: (v) => setState(() => _sessionMinutes = v),
                          divisions: 11,
                        ),
                        if (_newAyahsPerDay >
                            PlanSchedulePolicy.newAyahsFittingMinutes(
                              _sessionMinutes,
                            ))
                          Padding(
                            key: const Key('custom_plan_minutes_limit_hint'),
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              context.l10n.customPlanMinutesLimitHint(
                                context.numText(_sessionMinutes),
                                context.numText(
                                  PlanSchedulePolicy.newAyahsFittingMinutes(
                                    _sessionMinutes,
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
                          icon: Icons.tune_rounded,
                          title: context.l10n.customPlanDifficulty,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDifficultySelector(isDark, primaryColor),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Review Settings ──
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: _SectionTitle(
                            icon: Icons.replay_rounded,
                            title: context.l10n.customPlanAdvanced,
                            isDark: isDark,
                          ),
                          subtitle: Text(
                            context.l10n.customPlanAdvancedSubtitle,
                          ),
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            _buildReviewSettings(isDark, primaryColor),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Estimated Duration ──
                        _buildEstimatedDuration(isDark),

                        const SizedBox(height: AppSpacing.xl),

                        _PlanSummaryCard(
                          isDark: isDark,
                          ayahsPerDay: _newAyahsPerDay,
                          daysPerWeek: _availableDays,
                          sessionMinutes: _sessionMinutes,
                          difficulty: _difficulty,
                          // "من" = startSurahId (entry point), "إلى" = endSurahId (exit point)
                          startSurah: _startSurahId < _surahNames.length
                              ? _surahNames[_startSurahId]
                              : '${context.l10n.surah} $_startSurahId',
                          endSurah: _endSurahId < _surahNames.length
                              ? _surahNames[_endSurahId]
                              : '${context.l10n.surah} $_endSurahId',
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Save Button ──
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _save,
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
                                const Icon(Icons.save_rounded),
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
                        if (state is CustomPlanLoaded) ...[
                          const SizedBox(height: AppSpacing.md),
                          TextButton.icon(
                            onPressed: () =>
                                _showDeletePlanConfirmation(context),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
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
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Builder methods
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSurahRangeSelector(bool isDark, Color primary) {
    final directionForward = _startSurahId <= _endSurahId;
    final fromName = _startSurahId < _surahNames.length
        ? _surahNames[_startSurahId]
        : '${context.l10n.surah} $_startSurahId';
    final toName = _endSurahId < _surahNames.length
        ? _surahNames[_endSurahId]
        : '${context.l10n.surah} $_endSurahId';

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
          // "من سورة" = نقطة البداية العددية الأصغر (_startSurahId)
          // مثال جزء عم: من سورة النبأ (78) ... إلى سورة الناس (114)
          // الحفظ يسير تنازلياً: endSurahId (الناس) ← startSurahId (النبأ)
          _buildDropdownRow(
            label: context.l10n.customPlanFromSurah,
            value: _startSurahId,
            icon: Icons.first_page_rounded,
            isDark: isDark,
            onChanged: (v) {
              setState(() {
                _setStartSurah(v);
              });
            },
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          // "إلى سورة" = نقطة النهاية العددية الأكبر (_endSurahId)
          // مثال جزء عم: إلى سورة الناس (114)
          _buildDropdownRow(
            label: context.l10n.customPlanToSurah,
            value: _endSurahId,
            icon: Icons.last_page_rounded,
            isDark: isDark,
            onChanged: (v) {
              setState(() {
                _endSurahId = v;
                _clampStartAyahForSurah();
              });
            },
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          // Explicit direction hint — resolves the ascending/descending
          // ambiguity when "من" sits above "إلى" numerically (e.g. Juz Amma).
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  directionForward
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: primary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    directionForward
                        ? context.l10n.customPlanDirectionForward(
                            fromName,
                            toName,
                          )
                        : context.l10n.customPlanDirectionBackward(
                            fromName,
                            toName,
                          ),
                    style: AppTypography.bodySmall.copyWith(
                      color: context.tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.format_list_numbered_rounded,
                color: context.tokens.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.customPlanFromAyah,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 118,
                child: TextFormField(
                  controller: _startAyahController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = context.digitText(
                        LocaleNumberFormatter.western(newValue.text),
                      );
                      return newValue.copyWith(
                        text: text,
                        selection: TextSelection.collapsed(offset: text.length),
                      );
                    }),
                  ],
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.tokens.textPrimary,
                  ),
                  decoration: InputDecoration(
                    helperText: context.digitText(
                      context.digitText(
                        '1-${_ayahCountForSurah(_startSurahId)}',
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(
                      LocaleNumberFormatter.western(v),
                    );
                    if (parsed != null && parsed >= 1) {
                      setState(() => _startAyah = parsed);
                    }
                  },
                  validator: (v) {
                    final parsed = int.tryParse(
                      LocaleNumberFormatter.western((v ?? '').trim()),
                    );
                    final maxAyah = _ayahCountForSurah(_startSurahId);
                    if (parsed == null || parsed < 1) {
                      return context.l10n.customPlanInvalidAyah;
                    }
                    if (parsed > maxAyah) {
                      return context.l10n.customPlanSurahAyahLimit(
                        maxAyah,
                        context.numText(maxAyah),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required int value,
    required IconData icon,
    required bool isDark,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: context.tokens.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: context.tokens.textPrimary,
          ),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: value,
          underline: const SizedBox.shrink(),
          dropdownColor: context.tokens.surface,
          style: AppTypography.bodyMedium.copyWith(
            color: context.tokens.textPrimary,
          ),
          items: List.generate(
            114,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text(
                '${i + 1}. ${(i + 1) < _surahNames.length ? _surahNames[i + 1] : '${context.l10n.surah} ${i + 1}'}',
              ),
            ),
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _buildSliderCard({
    required String title,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ValueChanged<int> onChanged,
    int? divisions,
  }) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.tokens.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Text(
                  '$value $suffix',
                  style: AppTypography.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: divisions ?? (max - min),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  /// A child's plan belongs to the kids path, so choosing «طفل» leaves this
  /// adult plan screen for kids setup. An adult path in use is ended only
  /// after an explicit confirmation (same effect as "Reset path").
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
        return;
      }
      getIt<MemorizationPathResolver>().notifyChanged();
    }
    if (!mounted) return;
    context.go('${AppRoutes.memorizationPlus}?preferred=kids&setup=kids');
  }

  Widget _buildTargetUserSelector(bool isDark) {
    final items = [
      (
        PlanTargetUser.adult,
        context.l10n.customPlanAdult,
        Icons.person_rounded,
        AppColors.primary,
      ),
      (
        PlanTargetUser.child,
        context.l10n.customPlanChild,
        Icons.child_care_rounded,
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
        Icons.sentiment_satisfied_rounded,
        AppColors.success,
      ),
      (
        MemorizationDifficulty.moderate,
        context.l10n.customPlanDifficultyModerate,
        Icons.sentiment_neutral_rounded,
        Colors.amber,
      ),
      (
        MemorizationDifficulty.challenging,
        context.l10n.customPlanDifficultyChallenging,
        Icons.sentiment_dissatisfied_rounded,
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
            icon: Icons.update_rounded,
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
            icon: Icons.history_rounded,
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
              Icons.insights_rounded,
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════════════════════════════════════════

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
