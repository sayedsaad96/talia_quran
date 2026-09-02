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
import '../cubits/khatmah_cubit.dart';
import '../widgets/khatmah_progress_gauge.dart';

class KhatmahDashboardPage extends StatefulWidget {
  const KhatmahDashboardPage({
    super.key,
    this.cubit,
  });

  final KhatmahCubit? cubit;

  @override
  State<KhatmahDashboardPage> createState() => _KhatmahDashboardPageState();
}

class _KhatmahDashboardPageState extends State<KhatmahDashboardPage> {
  late final KhatmahCubit _cubit;
  bool _createdOwnCubit = false;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
    } else {
      try {
        _cubit = context.read<KhatmahCubit>();
      } catch (_) {
        _cubit = getIt<KhatmahCubit>();
        _createdOwnCubit = true;
      }
    }
    _cubit.load();
  }

  @override
  void dispose() {
    if (_createdOwnCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _showMushafLoggerDialog(BuildContext context, KhatmahPlan plan) {
    final controller = TextEditingController();
    final isArabic = context.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.gold),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                isArabic ? 'تسجيل قراءة من المصحف' : 'Log Physical Mushaf Reading',
                style: AppTypography.titleMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'أدخل رقم آخر صفحة قرأتها من المصحف الورقي (1 - 604):'
                  : 'Enter the last page read from your physical Mushaf (1 - 604):',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('khatmah_dashboard_mushaf_page_input'),
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: isArabic ? 'رقم الصفحة' : 'Page number',
                hintText: isArabic
                    ? 'مثال: ${plan.currentPage + 1}'
                    : 'e.g. ${plan.currentPage + 1}',
                prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            key: const Key('khatmah_dashboard_mushaf_save_button'),
            onPressed: () {
              final page = int.tryParse(controller.text.trim());
              if (page != null && page >= 1 && page <= KhatmahSchedulingEngine.totalPages) {
                _cubit.advancePage(page);
                Navigator.of(ctx).pop();
                context.showSnackBar(
                  isArabic
                      ? 'تم تسجيل قراءة الصفحة $page بنجاح'
                      : 'Logged page $page successfully',
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(isArabic ? 'حفظ التقدم' : 'Save Progress'),
          ),
        ],
      ),
    );
  }

  void _showAbandonConfirmDialog(BuildContext context) {
    final isArabic = context.isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isArabic ? 'إنهاء الختمة' : 'End Khatmah',
          style: AppTypography.titleMedium,
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من رغبتك في إنهاء هذه الختمة؟ يمكنك دائماً البدء من جديد بهدوء وبدون أي حرج.'
              : 'Are you sure you want to end this Khatmah? You can always start anew whenever you feel ready.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isArabic ? 'تراجع' : 'Cancel'),
          ),
          TextButton(
            key: const Key('khatmah_dashboard_abandon_confirm_button'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _cubit.abandonPlan();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(isArabic ? 'إنهاء الختمة' : 'End Khatmah'),
          ),
        ],
      ),
    );
  }

  Widget _buildDedicationBadge(KhatmahDedication dedication, bool isArabic, bool isDark) {
    final recipient = dedication.recipientName ?? '';
    String conditionLabel = '';
    if (dedication.condition == DedicationCondition.alive) {
      conditionLabel = isArabic ? 'حفظه الله' : 'Living';
    } else if (dedication.condition == DedicationCondition.deceased) {
      conditionLabel = isArabic ? 'رحمه الله' : 'Deceased';
    } else if (dedication.condition == DedicationCondition.sick) {
      conditionLabel = isArabic ? 'شفاه الله' : 'Healing';
    }

    final fullText = conditionLabel.isNotEmpty
        ? '$recipient ($conditionLabel)'
        : recipient;

    return Container(
      key: const Key('khatmah_dashboard_dedication_badge'),
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 14,
            color: AppColors.gold,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isArabic ? 'مهداة إلى: $fullText' : 'Dedicated to: $fullText',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.goldLight : AppColors.goldDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isArabic = context.isArabic;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return BlocProvider<KhatmahCubit>.value(
      value: _cubit,
      child: BlocBuilder<KhatmahCubit, KhatmahState>(
        builder: (context, state) {
          if (state is KhatmahLoading || state is KhatmahInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is KhatmahNoActivePlan) {
            return Scaffold(
              appBar: AppBar(
                title: Text(isArabic ? 'ختمة القرآن الكريم' : 'Quran Khatmah'),
                centerTitle: true,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pause_circle_outline_rounded,
                        size: 64,
                        color: primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isArabic
                            ? 'الختمة متوقفة مؤقتاً أو لا توجد خطة نشطة'
                            : 'Khatmah is paused or no active plan',
                        style: AppTypography.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        isArabic
                            ? 'يمكنك استئناف ختمتك الحالية في أي وقت أو بدء خطة جديدة بهدوء وسكينة'
                            : 'You can resume your current khatmah anytime or set up a new serene plan.',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        children: [
                          FilledButton.icon(
                            key: const Key('khatmah_dashboard_pause_resume_button'),
                            onPressed: () => _cubit.resume(),
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(isArabic ? 'استئناف' : 'Resume'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go(AppRoutes.khatmahSetup),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(
                              isArabic ? 'بدء ختمة جديدة' : 'Start New Khatmah',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          KhatmahPlan plan;
          int wirdStartPage;
          int wirdEndPage;

          if (state is KhatmahActive) {
            plan = state.plan;
            wirdStartPage = state.wirdStartPage;
            wirdEndPage = state.wirdEndPage;
          } else if (state is KhatmahWirdCompleted) {
            plan = state.plan;
            final wird = KhatmahSchedulingEngine.todaysWird(
              plan.currentPage,
              plan.targetPagesPerDay,
            );
            wirdStartPage = wird.startPage;
            wirdEndPage = wird.endPage;
          } else if (state is KhatmahCompleted) {
            plan = state.plan;
            wirdStartPage = 604;
            wirdEndPage = 604;
          } else {
            return const SizedBox.shrink();
          }

          final wirdPagesCount = wirdEndPage - wirdStartPage + 1;
          final wirdStartStr = isArabic
              ? MushafHizbHelper.toArabicNumber(wirdStartPage)
              : wirdStartPage.toString();
          final wirdEndStr = isArabic
              ? MushafHizbHelper.toArabicNumber(wirdEndPage)
              : wirdEndPage.toString();
          final wirdPagesCountStr = isArabic
              ? MushafHizbHelper.toArabicNumber(wirdPagesCount)
              : wirdPagesCount.toString();

          return Scaffold(
            appBar: AppBar(
              title: Text(
                isArabic ? 'لوحة الختمة' : 'Khatmah Dashboard',
                style: AppTypography.titleMedium,
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  key: const Key('khatmah_dashboard_abandon_button'),
                  tooltip: isArabic ? 'إنهاء الختمة' : 'End Khatmah',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _showAbandonConfirmDialog(context),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with Plan Title & Dedication Badge
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            plan.title,
                            key: const Key('khatmah_dashboard_title'),
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (plan.dedication.isDedicated &&
                              plan.dedication.recipientName != null &&
                              plan.dedication.recipientName!.isNotEmpty)
                            _buildDedicationBadge(
                              plan.dedication,
                              isArabic,
                              isDark,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Progress Gauge
                    KhatmahProgressGauge(plan: plan),
                    const SizedBox(height: AppSpacing.md),

                    // Today's Wird Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.darkSurfaceVariant,
                                  AppColors.darkCard,
                                ]
                              : [
                                  primary.withValues(alpha: 0.08),
                                  AppColors.lightCard,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_stories_rounded, color: primary, size: 22),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                isArabic ? 'ورد اليوم' : 'Today\'s Wird',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isArabic
                                    ? '$wirdPagesCountStr صفحات'
                                    : '$wirdPagesCount pages',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            isArabic
                                ? 'من صفحة $wirdStartStr إلى صفحة $wirdEndStr'
                                : 'Pages $wirdStartStr to $wirdEndStr',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.icon(
                            key: const Key('khatmah_dashboard_continue_reading_button'),
                            onPressed: () {
                              context.push(
                                '/quran/page/$wirdStartPage?mode=khatmah',
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            icon: const Icon(Icons.menu_book_rounded),
                            label: Text(
                              isArabic ? 'متابعة القراءة' : 'Continue Reading',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Physical Mushaf Logger Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bookmark_added_rounded,
                            color: AppColors.gold,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic
                                      ? 'قرأت من المصحف الورقي؟'
                                      : 'Read from physical Mushaf?',
                                  style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isArabic
                                      ? 'سجّل آخر صفحة قرأتها لمزامنة تقدمك'
                                      : 'Record your latest page to sync progress',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            key: const Key('khatmah_dashboard_log_mushaf_button'),
                            onPressed: () => _showMushafLoggerDialog(context, plan),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              side: BorderSide(color: primary),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            child: Text(isArabic ? 'تسجيل' : 'Log'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Adaptive Controls Section
                    Text(
                      isArabic ? 'خيارات التكيّف الهادئ' : 'Calm Adaptive Controls',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      children: [
                        // Calm adjustment: recalibrate end date
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('khatmah_dashboard_calm_adjustment_button'),
                            onPressed: () {
                              _cubit.calmAdjustment();
                              context.showSnackBar(
                                isArabic
                                    ? 'تمت إعادة ضبط موعد الختام بهدوء وسكينة'
                                    : 'End date recalibrated smoothly',
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                                horizontal: AppSpacing.xs,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            icon: const Icon(Icons.update_rounded, size: 18),
                            label: Text(
                              isArabic ? 'تعديل هادئ' : 'Calm Adjust',
                              style: AppTypography.labelMedium,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Mild compensation: add 1-2 pages/day
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('khatmah_dashboard_mild_compensation_button'),
                            onPressed: () {
                              _cubit.mildCompensation(1);
                              context.showSnackBar(
                                isArabic
                                    ? 'تمت إضافة صفحة يومياً للتعويض الخفيف'
                                    : 'Added 1 page/day mild compensation',
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                                horizontal: AppSpacing.xs,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            label: Text(
                              isArabic ? 'تعويض خفيف' : 'Mild Boost',
                              style: AppTypography.labelMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Pause / Resume button
                    OutlinedButton.icon(
                      key: const Key('khatmah_dashboard_pause_resume_button'),
                      onPressed: () {
                        if (plan.status == KhatmahStatus.active) {
                          _cubit.pause();
                        } else {
                          _cubit.resume();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      icon: Icon(
                        plan.status == KhatmahStatus.active
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(
                        plan.status == KhatmahStatus.active
                            ? (isArabic ? 'إيقاف مؤقت' : 'Pause')
                            : (isArabic ? 'استئناف' : 'Resume'),
                        style: AppTypography.labelMedium,
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
