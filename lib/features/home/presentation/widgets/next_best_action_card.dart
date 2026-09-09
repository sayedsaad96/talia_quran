import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/smart_coach_recommendation.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/home_cubit.dart';

class NextBestActionCard extends StatefulWidget {
  const NextBestActionCard({
    super.key,
    required this.state,
    required this.isDark,
    this.isKids = false,
  });

  final HomeLoaded state;
  final bool isDark;
  final bool isKids;

  @override
  State<NextBestActionCard> createState() => _NextBestActionCardState();
}

class _NextBestActionCardState extends State<NextBestActionCard> {
  String? _goal;

  @override
  void initState() {
    super.initState();
    _goal = getIt<SharedPreferences>().getString('user_primary_goal');
  }

  (String, String, IconData, String) _action(BuildContext context) {
    final coach = widget.state.coachRecommendation;
    if (coach != null) return _coachAction(context, coach);

    if (widget.isKids) {
      return (
        context.l10n.homeCurrentMission,
        context.l10n.homeStartKidsMission,
        Icons.star_rounded,
        AppRoutes.memorizationHub,
      );
    }
    if (widget.state.customPlan != null) {
      return (
        context.l10n.homeContinueTodaysPlan,
        context.l10n.planReadySmallStep,
        Icons.psychology_alt_rounded,
        AppRoutes.memorizationHub,
      );
    }
    if (widget.state.dailyWirdPageDetail != null) {
      return (
        context.l10n.readTodaysPortion,
        context.l10n.onePageMakesProgress,
        Icons.menu_book_rounded,
        '/quran/page/${widget.state.dailyWirdPageDetail!.pageNumber}',
      );
    }
    if (_goal == 'azkar') {
      return (
        context.l10n.timeForDhikr,
        context.l10n.startShortAzkarNow,
        Icons.volunteer_activism_rounded,
        '/azkar',
      );
    }
    if (_goal == 'child') {
      return (
        context.l10n.homeCurrentMission,
        context.l10n.homeChooseKidsPath,
        Icons.auto_stories_rounded,
        AppRoutes.memorizationHub,
      );
    }
    return (
      context.l10n.homeTodaysPlan,
      context.l10n.chooseReadingOrMemorization,
      Icons.auto_awesome_rounded,
      AppRoutes.memorizationHub,
    );
  }

  (String, String, IconData, String) _coachAction(
    BuildContext context,
    SmartCoachRecommendation coach,
  ) {
    final surahLabel = _coachSurahLabel(context, coach.surahId);
    final ayahLabel = _coachAyahLabel(context, coach);

    return switch (coach.kind) {
      SmartCoachRecommendationKind.reviewDueNear => (
        context.l10n.journeyReviewBeforeNewTitle,
        context.l10n.journeyReviewBeforeNewDesc('$surahLabel$ayahLabel'),
        Icons.history_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.reviewDueFar => (
        context.l10n.journeyLongTermReviewTitle,
        context.l10n.journeyLongTermReviewDesc('$surahLabel$ayahLabel'),
        Icons.schedule_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.memorizedReviewDue => (
        context.l10n.smartCoachMemorizedReviewDueTitle,
        context.l10n.smartCoachMemorizedReviewDueSubtitle(
          _coachSurahName(context, coach.surahId),
        ),
        Icons.verified_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.reviewWeakAyah => (
        context.l10n.journeyReviewDifficultAyahTitle,
        context.l10n.journeyReviewDifficultAyahDesc('$surahLabel$ayahLabel'),
        Icons.healing_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.continueDailyPlan => (
        context.l10n.journeyContinueDailyPlanTitle,
        context.l10n.journeyContinueDailyPlanDesc(
          coach.completedCount ?? 0,
          coach.totalCount ?? 0,
        ),
        Icons.today_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.memorizeNewAyahs => (
        context.l10n.journeyMemorizeNewAyahsTitle,
        context.l10n.journeyMemorizeNewAyahsDesc('$surahLabel$ayahLabel'),
        Icons.auto_awesome_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.kidsCurrentMission => (
        context.l10n.journeyCurrentMissionTitle,
        context.l10n.journeyCurrentMissionDesc,
        Icons.star_rounded,
        coach.route,
      ),
      SmartCoachRecommendationKind.continueV2Session => (
        context.l10n.journeyContinueSessionTitle,
        context.l10n.journeyContinueSessionDesc(surahLabel),
        Icons.play_circle_fill_rounded,
        coach.route,
      ),
    };
  }

  String _coachSurahName(BuildContext context, int? surahId) {
    if (surahId == null) return context.l10n.journeyFallbackSurah;
    return context.isArabic
        ? SurahNames.nameAr(surahId)
        : SurahNames.nameEn(surahId);
  }

  String _coachSurahLabel(BuildContext context, int? surahId) {
    if (surahId == null) return context.l10n.journeyFallbackSurah;
    return '${context.l10n.surah} ${_coachSurahName(context, surahId)}';
  }

  String _coachAyahLabel(BuildContext context, SmartCoachRecommendation coach) {
    final start = coach.startAyah;
    final end = coach.endAyah;
    if (start == null) return '';
    if (end == null || end == start) {
      return context.l10n.journeyAyahLabel(start);
    }
    return context.l10n.journeyAyahsLabel(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final action = _action(context);

    return Semantics(
      button: true,
      label: action.$1,
      hint: action.$2,
      child: InkWell(
        onTap: () => context.push(action.$4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: primary.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Icon(action.$3, color: primary, size: 30),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: textColor,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      action.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(context.forwardChevron, color: primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
