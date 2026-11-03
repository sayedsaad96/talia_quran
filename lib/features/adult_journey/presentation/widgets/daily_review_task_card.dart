import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../domain/entities/daily_review_task.dart';
import 'adult_journey_suggestion_tile.dart';

/// A projection of existing journey actions; it never records completion.
class DailyReviewTaskCard extends StatelessWidget {
  const DailyReviewTaskCard({
    super.key,
    required this.decision,
    required this.skin,
    required this.onStart,
    required this.onOtherOptions,
    required this.onChangeTime,
  });
  final DailyReviewTaskDecision decision;
  final HomeSkin skin;
  final VoidCallback onStart;
  final VoidCallback onOtherOptions;
  final VoidCallback onChangeTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (decision.suggestion case final suggestion?) ...[
          AdultJourneySuggestionTile(
            suggestion: suggestion,
            skin: skin,
            onOpen: onStart,
            onChangeTime: onChangeTime,
          ),
          if (decision.exceedsBudget)
            TextButton(
              onPressed: onStart,
              child: Text(l10n.dailyReviewContinue),
            ),
        ] else if (decision.status == DailyReviewTaskStatus.noReviews) ...[
          Text(l10n.dailyReviewNoReviews),
          TextButton(
            onPressed: onStart,
            child: Text(l10n.adultJourneyNeedsPlanTitle),
          ),
        ] else if (decision.status == DailyReviewTaskStatus.noDueReview)
          Text(l10n.dailyReviewNoDue)
        else if (decision.status == DailyReviewTaskStatus.unavailable)
          Text(l10n.dailyReviewUnavailable),
        TextButton(
          onPressed: onOtherOptions,
          child: Text(l10n.dailyReviewOtherOptions),
        ),
      ],
    );
  }
}
