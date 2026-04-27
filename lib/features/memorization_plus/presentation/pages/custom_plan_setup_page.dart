import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran/data/datasources/quran_local_datasource.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/custom_plan_cubit.dart';

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

  int _startSurahId = 1;
  int _endSurahId = 114;
  int _startAyah = 1;
  int _newAyahsPerDay = 3;
  int _availableDays = 7;
  int _sessionMinutes = 30;
  MemorizationDifficulty _difficulty = MemorizationDifficulty.moderate;
  bool _enableNearRevision = true;
  bool _enableFarRevision = true;
  int _nearRevisionCount = 5;
  int _farRevisionCount = 3;

  /// Surah names loaded from data layer (1-indexed, index 0 is placeholder)
  List<String> _surahNames = [''];

  @override
  void initState() {
    super.initState();
    _loadSurahNames();
  }

  Future<void> _loadSurahNames() async {
    try {
      final surahs = await getIt<QuranLocalDatasource>().getSurahs();
      if (mounted) {
        setState(() {
          _surahNames = ['', ...surahs.map((s) => s.nameAr)];
        });
      }
    } catch (_) {
      // Fallback: generate placeholder names
      if (mounted) {
        setState(() {
          _surahNames = List.generate(115, (i) => i == 0 ? '' : 'سورة $i');
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _populateFromExisting(CustomMemorizationPlan plan) {
    _nameController.text = plan.name;
    _startSurahId = plan.startSurahId;
    _endSurahId = plan.endSurahId;
    _startAyah = plan.startAyah;
    _newAyahsPerDay = plan.newAyahsPerDay;
    _availableDays = plan.availableDaysPerWeek;
    _sessionMinutes = plan.sessionMinutes;
    _difficulty = plan.difficulty;
    _enableNearRevision = plan.enableNearRevision;
    _enableFarRevision = plan.enableFarRevision;
    _nearRevisionCount = plan.nearRevisionCount;
    _farRevisionCount = plan.farRevisionCount;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

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
    );

    context.read<CustomPlanCubit>().savePlan(plan);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: BlocConsumer<CustomPlanCubit, CustomPlanState>(
        listener: (context, state) {
          if (state is CustomPlanSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم حفظ الخطة بنجاح ✅'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            // Navigate to daily plan with the custom plan's start surah
            context.pushReplacement(
              '/memorization-plus/daily-plan',
              extra: {'surahId': state.plan.startSurahId},
            );
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
                backgroundColor: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6C3483),
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'خطتك المخصصة',
                              style: AppTypography.displaySmall.copyWith(
                                color: Colors.white,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'صمّم نظام حفظ يناسبك',
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
                        // ── Plan Name ──
                        _SectionTitle(
                          icon: Icons.edit_rounded,
                          title: 'اسم الخطة',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _StyledTextField(
                          controller: _nameController,
                          hintText: 'مثال: خطتي لحفظ جزء عمّ',
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'يرجى إدخال اسم للخطة';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Surah Range ──
                        _SectionTitle(
                          icon: Icons.menu_book_rounded,
                          title: 'نطاق السور',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSurahRangeSelector(isDark, primaryColor),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Daily Load ──
                        _SectionTitle(
                          icon: Icons.today_rounded,
                          title: 'الحِمل اليومي',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSliderCard(
                          title: 'آيات جديدة يومياً',
                          value: _newAyahsPerDay,
                          min: 1,
                          max: 10,
                          suffix: 'آية',
                          icon: Icons.auto_stories_rounded,
                          color: Colors.amber,
                          isDark: isDark,
                          onChanged: (v) =>
                              setState(() => _newAyahsPerDay = v),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // ── Schedule ──
                        _SectionTitle(
                          icon: Icons.calendar_month_rounded,
                          title: 'الجدول الزمني',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSliderCard(
                          title: 'أيام الحفظ في الأسبوع',
                          value: _availableDays,
                          min: 1,
                          max: 7,
                          suffix: 'يوم',
                          icon: Icons.date_range_rounded,
                          color: Colors.blueAccent,
                          isDark: isDark,
                          onChanged: (v) =>
                              setState(() => _availableDays = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSliderCard(
                          title: 'مدة الجلسة',
                          value: _sessionMinutes,
                          min: 10,
                          max: 120,
                          suffix: 'دقيقة',
                          icon: Icons.timer_rounded,
                          color: Colors.teal,
                          isDark: isDark,
                          onChanged: (v) =>
                              setState(() => _sessionMinutes = v),
                          divisions: 11,
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Difficulty ──
                        _SectionTitle(
                          icon: Icons.tune_rounded,
                          title: 'مستوى الصعوبة',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDifficultySelector(isDark, primaryColor),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Review Settings ──
                        _SectionTitle(
                          icon: Icons.replay_rounded,
                          title: 'إعدادات المراجعة',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildReviewSettings(isDark, primaryColor),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Estimated Duration ──
                        _buildEstimatedDuration(isDark),

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
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusLg),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded),
                                const SizedBox(width: 12),
                                Text(
                                  'حفظ وبدء الخطة',
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
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('حذف الخطة'),
                                  content: const Text(
                                      'هل أنت متأكد من حذف الخطة الحالية؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('إلغاء'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        context
                                            .read<CustomPlanCubit>()
                                            .deletePlan();
                                      },
                                      child: const Text(
                                        'حذف',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent),
                            label: Text(
                              'حذف الخطة الحالية',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.redAccent,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          _buildDropdownRow(
            label: 'من سورة',
            value: _startSurahId,
            icon: Icons.first_page_rounded,
            isDark: isDark,
            onChanged: (v) {
              setState(() {
                _startSurahId = v;
                if (_endSurahId < v) _endSurahId = v;
              });
            },
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          _buildDropdownRow(
            label: 'إلى سورة',
            value: _endSurahId,
            icon: Icons.last_page_rounded,
            isDark: isDark,
            onChanged: (v) {
              setState(() {
                _endSurahId = v;
                if (_startSurahId > v) _startSurahId = v;
              });
            },
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          Row(
            children: [
              Icon(
                Icons.format_list_numbered_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'من آية رقم',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: _startAyah.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed >= 1) {
                      setState(() => _startAyah = parsed);
                    }
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
        Icon(
          icon,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: value,
          underline: const SizedBox.shrink(),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          items: List.generate(
            114,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text('${i + 1}. ${(i + 1) < _surahNames.length ? _surahNames[i + 1] : 'سورة ${i + 1}'}'),
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
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
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

  Widget _buildDifficultySelector(bool isDark, Color primary) {
    final items = [
      (MemorizationDifficulty.easy, 'سهل', Icons.sentiment_satisfied_rounded,
          Colors.green),
      (MemorizationDifficulty.moderate, 'متوسط',
          Icons.sentiment_neutral_rounded, Colors.amber),
      (MemorizationDifficulty.challenging, 'صعب',
          Icons.sentiment_dissatisfied_rounded, Colors.redAccent),
    ];

    return Row(
      children: items.map((item) {
        final isSelected = _difficulty == item.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? item.$4.withValues(alpha: 0.15)
                    : isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
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
                          : isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
            title: 'المراجعة القريبة',
            subtitle: 'مراجعة آيات آخر 5 أيام',
            value: _enableNearRevision,
            icon: Icons.update_rounded,
            color: Colors.blueAccent,
            isDark: isDark,
            onChanged: (v) => setState(() => _enableNearRevision = v),
          ),
          if (_enableNearRevision) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildMiniSlider(
              label: 'عدد آيات المراجعة القريبة',
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
            title: 'المراجعة البعيدة',
            subtitle: 'تكرار ذكي للآيات القديمة',
            value: _enableFarRevision,
            icon: Icons.history_rounded,
            color: Colors.deepPurple,
            isDark: isDark,
            onChanged: (v) => setState(() => _enableFarRevision = v),
          ),
          if (_enableFarRevision) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildMiniSlider(
              label: 'عدد آيات المراجعة البعيدة',
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
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: color,
          onChanged: onChanged,
        ),
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
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Text(
          '$value',
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
    // rough estimate
    final totalSurahs = _endSurahId - _startSurahId + 1;
    final totalAyahsEstimate = totalSurahs * 20; // rough avg
    final sessionsPerWeek = _availableDays;
    final ayahsPerSession = _newAyahsPerDay;
    final totalSessions = (totalAyahsEstimate / ayahsPerSession).ceil();
    final weeks = (totalSessions / sessionsPerWeek).ceil();
    final months = (weeks / 4.3).ceil();

    String durationText;
    if (months > 12) {
      final years = (months / 12.0);
      durationText = '${years.toStringAsFixed(1)} سنة تقريباً';
    } else if (months > 1) {
      durationText = '$months شهر تقريباً';
    } else {
      durationText = '$weeks أسبوع تقريباً';
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
        border: Border.all(
          color: Colors.deepPurple.withValues(alpha: 0.3),
        ),
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
                  'المدة المقدّرة للإنهاء',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  durationText,
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$totalSurahs سورة · ~$totalAyahsEstimate آية',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
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
        Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
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
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
