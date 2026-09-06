import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
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
        subtitle = context.l10n.dailyWirdSubtitle;
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
}
