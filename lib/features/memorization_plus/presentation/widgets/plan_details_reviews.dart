import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/plan_details.dart';
import 'plan_details_section.dart';

class PlanDetailsReviews extends StatelessWidget {
  const PlanDetailsReviews({super.key, required this.details});
  final PlanDetails details;

  @override
  Widget build(BuildContext context) => PlanDetailsSection(
    title: context.l10n.planDetailsReviews,
    children: [
      PlanDetailsRow(
        label: context.l10n.planDetailsDue,
        value: context.numText(details.metrics.dueReviews),
      ),
      PlanDetailsRow(
        label: context.l10n.planDetailsOverdue,
        value: context.numText(details.metrics.overdueReviews),
      ),
      PlanDetailsRow(
        label: context.l10n.planDetailsReviewEvents,
        value: context.numText(details.metrics.totalReviewEvents),
      ),
      PlanDetailsRow(
        label: context.l10n.planDetailsNextReview,
        value: _nextReview(context),
      ),
    ],
  );

  String _nextReview(BuildContext context) {
    if (details.metrics.dueReviews > 0) return context.l10n.planDetailsDue;
    final date = details.nextReviewAt?.toLocal();
    if (date == null) return context.l10n.planDetailsNoReviews;
    final localized = MaterialLocalizations.of(context);
    return context.digitText(
      '${localized.formatMediumDate(date)} '
      '${localized.formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
    );
  }
}

class PlanDetailsToday extends StatelessWidget {
  const PlanDetailsToday({super.key, required this.details});
  final PlanDetails details;

  @override
  Widget build(BuildContext context) {
    final today = details.dailyPlan;
    return PlanDetailsSection(
      title: context.l10n.dailyPlanHeaderTitle,
      children: [
        if (today == null)
          Text(context.l10n.planDetailsTodayUnavailable)
        else ...[
          if (today.isReviewDay) Text(context.l10n.planDetailsRestDay),
          if (today.newMemorizationBlocked)
            Text(context.l10n.planDetailsBacklog),
          if (today.isRequiredPlanCompleted)
            Text(context.l10n.planDetailsTodayDone),
          if (today.totalItems == 0) Text(context.l10n.planDetailsTodayEmpty),
          PlanDetailsRow(
            label: context.l10n.planDetailsTodayNew,
            value: context.numText(today.newAyahs.length),
          ),
          PlanDetailsRow(
            label: context.l10n.planDetailsTodayReview,
            value: context.numText(details.todayReviewAyahs),
          ),
          Text(
            context.l10n.dailyPlanProgressCount(
              context.numText(today.requiredCompletedCount),
              context.numText(today.totalItems),
            ),
          ),
          LinearProgressIndicator(value: today.requiredProgress),
        ],
        Text(
          context.l10n.planDetailsTodayHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
