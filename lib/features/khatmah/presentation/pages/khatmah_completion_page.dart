import 'package:confetti/confetti.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_spacing.dart';
import '../khatmah_localizations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../domain/entities/khatmah_reading_result.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../../../../core/identity/account_data_barrier.dart';

class KhatmahCompletionPage extends StatefulWidget {
  const KhatmahCompletionPage({
    super.key,
    this.completion,
    this.enableConfetti = true,
    this.onReadDua,
    this.onShare,
    this.onHome,
  });

  final KhatmahReadingResult? completion;
  final bool enableConfetti;
  final VoidCallback? onReadDua;
  final VoidCallback? onShare;
  final VoidCallback? onHome;

  @override
  State<KhatmahCompletionPage> createState() => _KhatmahCompletionPageState();
}

class _KhatmahCompletionPageState extends State<KhatmahCompletionPage> {
  late final ConfettiController _confettiController;
  StreamSubscription<void>? _authorityChanges;
  bool _confettiStarted = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    final authority = widget.completion?.plan.authority;
    if (authority is AccountDataLease) {
      _authorityChanges = authority.changes.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_confettiStarted) {
      _confettiStarted = true;
      if (widget.completion?.isValidCompletion == true &&
          widget.enableConfetti &&
          !MediaQuery.disableAnimationsOf(context)) {
        _confettiController.play();
      }
    }
  }

  @override
  void dispose() {
    unawaited(_authorityChanges?.cancel());
    _confettiController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date, bool isArabic) {
    if (isArabic) {
      return '${MushafHizbHelper.toArabicNumber(date.year)}/${MushafHizbHelper.toArabicNumber(date.month)}/${MushafHizbHelper.toArabicNumber(date.day)}';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _shareAchievement(KhatmahReadingResult completion, bool isArabic) {
    if (!completion.isValidCompletion) return;
    final plan = completion.plan;
    if (widget.onShare != null) {
      widget.onShare!();
      return;
    }

    final title = plan.title;
    final totalDays = completion.actualElapsedDays;
    final totalDaysStr = isArabic
        ? MushafHizbHelper.toArabicNumber(totalDays)
        : totalDays.toString();

    final buffer = StringBuffer(
      context.l10n.khatmahShareSummary(title, totalDaysStr),
    );
    if (plan.dedication.isDedicated) {
      buffer.writeln();
      buffer.writeln(
        context.l10n.khatmahDedicatedTo(plan.dedication.recipientName ?? ''),
      );
    }
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isArabic = context.isArabic;
    final gold = isDark ? AppColors.goldLight : AppColors.gold;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final completion = widget.completion;
    if (completion == null || !completion.isValidCompletion) {
      return Scaffold(
        body: Center(
          child: Text(context.l10n.khatmahNoSavedCompletionAvailable),
        ),
      );
    }
    final plan = completion.plan;
    final title = plan.title;
    final daysTaken = completion.actualElapsedDays;
    final daysTakenStr = isArabic
        ? MushafHizbHelper.toArabicNumber(daysTaken)
        : daysTaken.toString();
    final completedDate = completion.historyEntry!.completedDate.toLocal();
    final completedDateStr = _formatDate(completedDate, isArabic);

    final hasDedication = plan.dedication.isDedicated;
    final dedication = plan.dedication;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Confetti emitter
          if (widget.enableConfetti)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.gold,
                  AppColors.goldLight,
                  AppColors.primary,
                  AppColors.primaryLight,
                  Colors.amber,
                ],
                numberOfParticles: 35,
                gravity: 0.25,
              ),
            ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Islamic Arch / Star celebratory badge
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withValues(alpha: 0.15),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gold.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 52,
                        color: gold,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Congratulatory Title
                  Text(
                    context.l10n.khatmahCongratulations,
                    textAlign: TextAlign.center,
                    style: AppTypography.displaySmall.copyWith(
                      color: gold,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Milestone Summary Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceAround,
                      runSpacing: AppSpacing.md,
                      spacing: AppSpacing.md,
                      children: [
                        _StatItem(
                          label: context.l10n.khatmahPagesLabel,
                          value: isArabic
                              ? MushafHizbHelper.toArabicNumber(
                                  KhatmahSchedulingEngine.totalPages,
                                )
                              : KhatmahSchedulingEngine.totalPages.toString(),
                          icon: Icons.auto_stories_rounded,
                          color: gold,
                        ),

                        _StatItem(
                          label: context.l10n.khatmahDuration,
                          value: context.l10n.khatmahDays(
                            (daysTakenStr).toString(),
                          ),
                          icon: Icons.calendar_today_rounded,
                          color: AppColors.primaryLight,
                        ),

                        _StatItem(
                          label: context.l10n.khatmahCompleted,
                          value: completedDateStr,
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // Tailored Dedication Section (if dedicated)
                  if (hasDedication) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      key: const Key('khatmah_completion_dedication_section'),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXl,
                        ),
                        border: Border.all(
                          color: gold.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.l10n.khatmahDedicationOfReward,
                            style: AppTypography.titleMedium.copyWith(
                              color: gold,
                            ),
                          ),
                          if (dedication.relationship != null)
                            Text(
                              localizedKhatmahRelationship(
                                context,
                                dedication.relationship,
                              ),
                            ),
                          if (dedication.condition != null)
                            Text(
                              localizedKhatmahCondition(
                                context,
                                dedication.condition,
                              ),
                            ),
                          if (dedication.customNote?.isNotEmpty == true)
                            Text(
                              context.l10n.khatmahUserNote(
                                dedication.customNote!,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.l10n.khatmahDedicatedTo(
                              dedication.recipientName ?? '',
                            ),
                            textAlign: TextAlign.center,
                            textDirection: context.textDirection,
                            style: TextStyle(
                              fontFamily: 'Noto_Naskh_Arabic',
                              fontSize: 16,
                              height: 1.9,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),

                  // Action Buttons
                  if (completion.historyEntry?.certificate != null) ...[
                    OutlinedButton.icon(
                      key: const Key('khatmah_completion_certificate_button'),
                      onPressed: () {
                        if (!completion.isValidCompletion) return;
                        context.push(
                          AppRoutes.certificate,
                          extra: <String, dynamic>{
                            'award': completion.historyEntry!.certificate!,
                            'userName': context.l10n.taliaUser,
                          },
                        );
                      },
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: Text(context.l10n.myCertificates),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  // 1. Read Du'a Khatm al-Quran
                  FilledButton.icon(
                    key: const Key('khatmah_completion_read_dua_button'),
                    onPressed: () {
                      if (widget.onReadDua != null) {
                        widget.onReadDua!();
                      } else {
                        context.push(
                          AppRoutes.khatmDua,
                          extra: plan.dedication,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(
                      context.l10n.khatmahReadDuAKhatmAlQuran,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 2. Share Achievement
                  OutlinedButton.icon(
                    key: const Key('khatmah_completion_share_button'),
                    onPressed: () => _shareAchievement(completion, isArabic),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gold,
                      side: BorderSide(color: gold.withValues(alpha: 0.6)),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: Text(
                      context.l10n.khatmahShareAchievement,
                      style: AppTypography.labelLarge.copyWith(
                        color: gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 3. Return to Home
                  TextButton.icon(
                    key: const Key('khatmah_completion_home_button'),
                    onPressed: () {
                      if (widget.onHome != null) {
                        widget.onHome!();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: Text(
                      context.l10n.khatmahBackToHome,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
