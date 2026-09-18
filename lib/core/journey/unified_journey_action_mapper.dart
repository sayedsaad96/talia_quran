import 'package:flutter/material.dart';
import '../constants/surah_names.dart';
import '../extensions/context_extensions.dart';
import '../memorization/smart_coach_recommendation.dart';
import '../../features/memorization_plus/domain/entities/memorization_recommendation.dart';
import 'unified_journey_action.dart';
import 'unified_journey_input.dart';
import 'journey_presentation_data.dart';
import 'resume_session_presentation_input.dart';
import 'resume_session_presentation_mapper.dart';

class UnifiedJourneyActionMapper {
  const UnifiedJourneyActionMapper();

  JourneyPresentationData map(BuildContext context, UnifiedJourneyAction action) {
    if (action.actionType == UnifiedJourneyActionType.resumeSession) {
      return const ResumeSessionPresentationMapper().map(
        ResumeSessionPresentationInput(
          route: action.route,
          isArabic: context.isArabic,
          l10n: context.l10n,
          metadata: action.metadata,
        ),
      );
    }

    final coach = action.coachRecommendation;
    if (coach != null) return _mapCoach(context, coach);

    String title = '';
    String subtitle = '';

    switch (action.actionType) {
      case UnifiedJourneyActionType.criticalAlert:
        final typeStr = action.metadata['learningAlertType'];
        if (typeStr == RecommendationType.overloadRisk.name) {
          title = context.l10n.learningAlertReduceNewTitle;
          subtitle = context.l10n.learningAlertReduceNewSubtitle;
        } else if (typeStr == RecommendationType.leechRecovery.name) {
          title = context.l10n.learningAlertFocusWeakTitle;
          subtitle = context.l10n.learningAlertFocusWeakSubtitle;
        } else {
          title = context.l10n.learningAlertGenericTitle;
          subtitle = context.l10n.learningAlertGenericSubtitle;
        }
        break;

      case UnifiedJourneyActionType.reviewBacklog:
        final overdue = action.metadata['overdueAyahs'] ?? '0';
        title = context.l10n.reviewBacklogTitle;
        subtitle = context.l10n.reviewBacklogSubtitle(overdue.toString());
        break;

      case UnifiedJourneyActionType.smartPlan:
        final planTypeStr = action.metadata['smartPlanType'];
        if (planTypeStr == SmartPlanType.customPlan.name) {
          title = context.l10n.smartPlanCustomTitle;
        } else if (planTypeStr == SmartPlanType.reviewPlan.name) {
          title = context.l10n.smartPlanReviewTitle;
        } else {
          title = context.l10n.smartPlanTodayTitle;
        }
        subtitle = context.l10n.smartPlanSubtitle;
        break;

      case UnifiedJourneyActionType.dailyReading:
        title = context.l10n.dailyWirdTitle;
        final pageStr = action.metadata['pageNumber'];
        final surahName = context.isArabic
            ? action.metadata['surahNameAr']
            : action.metadata['surahNameEn'];
        if (pageStr != null && surahName != null && surahName.isNotEmpty) {
          subtitle = context.l10n.homeDailyWirdSurahPage(pageStr, surahName);
        } else if (pageStr != null) {
          subtitle = context.l10n.homeDailyWirdPage(pageStr);
        } else {
          subtitle = context.l10n.dailyWirdSubtitle;
        }
        break;

      case UnifiedJourneyActionType.khatmah:
        title = context.l10n.khatmahContinueTitle;
        subtitle = context.l10n.khatmahContinueSubtitle;
        break;

      case UnifiedJourneyActionType.explore:
        if (action.intent == JourneyIntent.azkar) {
          title = context.l10n.exploreAzkarTitle;
          subtitle = context.l10n.exploreAzkarSubtitle;
        } else if (action.source == 'KidsMode' || action.source == 'UserGoal') {
          title = context.l10n.exploreMissionTitle;
          subtitle = context.l10n.exploreMissionSubtitle;
        } else {
          title = context.l10n.exploreQuranTitle;
          subtitle = context.l10n.exploreQuranSubtitle;
        }
        break;

      case UnifiedJourneyActionType.resumeSession:
        break;
    }

    return JourneyPresentationData(
      title: title,
      subtitle: subtitle,
      icon: _getIconForIntent(action.intent),
      route: action.route,
    );
  }

  IconData _getIconForIntent(JourneyIntent intent) {
    return switch (intent) {
      JourneyIntent.resume => Icons.play_circle_fill_rounded,
      JourneyIntent.review => Icons.history_rounded,
      JourneyIntent.memorize => Icons.auto_awesome_rounded,
      JourneyIntent.reading => Icons.menu_book_rounded,
      JourneyIntent.azkar => Icons.volunteer_activism_rounded,
      JourneyIntent.explore => Icons.explore_rounded,
    };
  }

  JourneyPresentationData _mapCoach(
    BuildContext context,
    SmartCoachRecommendation coach,
  ) {
    final surahName = coach.surahId == null
        ? context.l10n.journeyFallbackSurah
        : (context.isArabic
              ? SurahNames.nameAr(coach.surahId!)
              : SurahNames.nameEn(coach.surahId!));
    final surahLabel = coach.surahId == null
        ? surahName
        : '${context.l10n.surah} $surahName';
    final ayahLabel = coach.startAyah == null
        ? ''
        : coach.endAyah == null || coach.endAyah == coach.startAyah
        ? context.l10n.journeyAyahLabel(coach.startAyah!)
        : context.l10n.journeyAyahsLabel(coach.startAyah!, coach.endAyah!);
    final values = switch (coach.kind) {
      SmartCoachRecommendationKind.reviewDueNear => (
        context.l10n.journeyReviewBeforeNewTitle,
        context.l10n.journeyReviewBeforeNewDesc('$surahLabel$ayahLabel'),
        Icons.history_rounded,
      ),
      SmartCoachRecommendationKind.reviewDueFar => (
        context.l10n.journeyLongTermReviewTitle,
        context.l10n.journeyLongTermReviewDesc('$surahLabel$ayahLabel'),
        Icons.schedule_rounded,
      ),
      SmartCoachRecommendationKind.memorizedReviewDue => (
        context.l10n.smartCoachMemorizedReviewDueTitle,
        context.l10n.smartCoachMemorizedReviewDueSubtitle(surahName),
        Icons.verified_rounded,
      ),
      SmartCoachRecommendationKind.reviewWeakAyah => (
        context.l10n.journeyReviewDifficultAyahTitle,
        context.l10n.journeyReviewDifficultAyahDesc('$surahLabel$ayahLabel'),
        Icons.healing_rounded,
      ),
      SmartCoachRecommendationKind.continueDailyPlan => (
        context.l10n.journeyContinueDailyPlanTitle,
        context.l10n.journeyContinueDailyPlanDesc(
          coach.completedCount ?? 0,
          coach.totalCount ?? 0,
        ),
        Icons.today_rounded,
      ),
      SmartCoachRecommendationKind.memorizeNewAyahs => (
        context.l10n.journeyMemorizeNewAyahsTitle,
        context.l10n.journeyMemorizeNewAyahsDesc('$surahLabel$ayahLabel'),
        Icons.auto_awesome_rounded,
      ),
      SmartCoachRecommendationKind.kidsCurrentMission => (
        context.l10n.journeyCurrentMissionTitle,
        context.l10n.journeyCurrentMissionDesc,
        Icons.star_rounded,
      ),
      SmartCoachRecommendationKind.continueV2Session => (
        context.l10n.journeyContinueSessionTitle,
        context.l10n.journeyContinueSessionDesc(surahLabel),
        Icons.play_circle_fill_rounded,
      ),
    };
    return JourneyPresentationData(
      title: values.$1,
      subtitle: values.$2,
      icon: values.$3,
      route: coach.route,
    );
  }
}
