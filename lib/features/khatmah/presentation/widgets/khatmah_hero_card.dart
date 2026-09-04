import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/khatmah_plan.dart';

class KhatmahHeroCard extends StatefulWidget {
  const KhatmahHeroCard({
    super.key,
    this.plan,
    this.error,
    this.onRetry,
    this.now,
    required this.isDark,
    this.margin = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  final KhatmahPlan? plan;
  final Object? error;
  final VoidCallback? onRetry;
  final DateTime Function()? now;
  final bool isDark;
  final EdgeInsetsGeometry margin;

  @override
  State<KhatmahHeroCard> createState() => _KhatmahHeroCardState();
}

class _KhatmahHeroCardState extends State<KhatmahHeroCard>
    with WidgetsBindingObserver {
  Timer? _rollover;
  KhatmahPlan? get plan => widget.plan;
  bool get isDark => widget.isDark;
  EdgeInsetsGeometry get margin => widget.margin;
  DateTime get _now => widget.now?.call() ?? DateTime.now();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleRollover();
  }

  void _scheduleRollover() {
    _rollover?.cancel();
    final now = _now;
    _rollover = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (!mounted) return;
        setState(() {});
        _scheduleRollover();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleRollover();
    }
  }

  @override
  void dispose() {
    _rollover?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = plan;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    if (widget.error != null) {
      return Card(
        margin: margin,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.khatmahUnableToLoadYourKhatmah),
              TextButton(
                onPressed: widget.onRetry,
                child: Text(context.l10n.khatmahRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (currentPlan == null || currentPlan.status == KhatmahStatus.completed) {
      return Card(
        margin: margin,
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        elevation: 0,
        child: InkWell(
          key: const Key('khatmah_hero_start_button'),
          onTap: () => context.push('/khatmah/setup'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: primary, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    context.l10n.khatmahStartAction,
                    style: AppTypography.labelLarge.copyWith(color: primary),
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      );
    }

    final today = _now;
    final wird = currentPlan.dailyTargetFor(today);
    final dailyComplete = currentPlan.isDailyTargetComplete(today);
    final isPaused = currentPlan.status == KhatmahStatus.paused;

    return Card(
      margin: margin,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      elevation: 0,
      child: InkWell(
        key: isPaused ? const Key('khatmah_hero_resume_button') : null,
        onTap: () => context.push(
          isPaused
              ? '/khatmah/dashboard'
              : '/quran/page/${currentPlan.nextUnreadPage}?mode=khatmah',
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      currentPlan.title,
                      style: AppTypography.labelLarge.copyWith(color: primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${(currentPlan.progressPercentage * 100).toStringAsFixed(0)}%',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                child: LinearProgressIndicator(
                  value: currentPlan.progressPercentage,
                  backgroundColor: primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isPaused
                    ? context.l10n.khatmahPausedSummary
                    : context.l10n.khatmahTodayRange(
                        wird.startPage.toString(),
                        wird.endPage.toString(),
                        dailyComplete
                            ? context.l10n.khatmahDailyCompletedSuffix
                            : '',
                      ),
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                isPaused
                    ? context.l10n.khatmahResumeAction
                    : context.l10n.khatmahContinueReading,
              ),
              if (currentPlan.dedication.isDedicated &&
                  currentPlan.dedication.recipientName != null &&
                  currentPlan.dedication.recipientName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    context.l10n.khatmahDedicatedTo(
                      currentPlan.dedication.recipientName!,
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
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
