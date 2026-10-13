import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/journey/unified_journey_action_mapper.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../domain/entities/adult_journey_suggestion.dart';

/// One suggestion row. Every estimate is labelled approximate; a missing
/// estimate says the duration is unavailable. [onOpen] is null when the
/// destination is unknown, which makes the row informational only.
class AdultJourneySuggestionTile extends StatelessWidget {
  const AdultJourneySuggestionTile({
    super.key,
    required this.suggestion,
    required this.skin,
    required this.onOpen,
    required this.onChangeTime,
  });

  final AdultJourneySuggestion suggestion;
  final HomeSkin skin;
  final VoidCallback? onOpen;
  final VoidCallback onChangeTime;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, icon) = _content(context);
    // GlassPanel paints a decorated box above its Material, which would hide
    // the ListTile ink, so the tile brings its own transparent Material.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: skin.accent),
        title: Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: skin.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: _subtitle(context, subtitle),
        trailing: onOpen == null ? null : Icon(context.forwardChevron),
        onTap: onOpen,
      ),
    );
  }

  /// Detail line with the approximate time, plus the over-budget note and the
  /// change-time action when the item is longer than today's choice.
  Widget _subtitle(BuildContext context, String subtitle) {
    final l10n = context.l10n;
    final minutes = suggestion.estimatedMinutes;
    final estimate = minutes == null
        ? l10n.adultJourneyDurationUnavailable
        : l10n.adultJourneyApproxMinutes(context.numText(minutes));
    final detail = [
      if (subtitle.isNotEmpty) subtitle,
      estimate,
    ].join(context.listSeparator);
    final style = AppTypography.bodySmall.copyWith(color: skin.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail, style: style),
        if (suggestion.exceedsBudget) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.adultJourneyExceedsBudget,
            key: const ValueKey('adult_exceeds_note'),
            style: style,
          ),
          TextButton(
            key: const ValueKey('adult_change_time'),
            onPressed: onChangeTime,
            child: Text(l10n.adultJourneyChangeTime),
          ),
        ],
      ],
    );
  }

  (String, String, IconData) _content(BuildContext context) {
    final l10n = context.l10n;
    final action = suggestion.action;
    switch (suggestion.launchKind) {
      case AdultJourneyLaunchKind.resume:
        return (
          l10n.adultJourneyResumeTitle,
          l10n.adultJourneyResumeSubtitle,
          TaliaIcons.playCircleFilled,
        );
      case AdultJourneyLaunchKind.setupPlan:
        final noReview =
            suggestion.reason == AdultJourneySuggestionReason.noReview;
        return (
          noReview
              ? l10n.adultJourneyNoReviewTitle
              : l10n.adultJourneyNeedsPlanTitle,
          noReview
              ? l10n.adultJourneyNoReviewSubtitle
              : l10n.adultJourneyNeedsPlanSubtitle,
          TaliaIcons.hifz,
        );
      default:
        if (action != null) {
          final data = const UnifiedJourneyActionMapper().map(context, action);
          return (data.title, data.subtitle, data.icon);
        }
        return _synthetic(context);
    }
  }

  (String, String, IconData) _synthetic(BuildContext context) {
    final l10n = context.l10n;
    return switch (suggestion.launchKind) {
      AdultJourneyLaunchKind.memorize || AdultJourneyLaunchKind.review => (
        l10n.adultJourneyOpenMemorization,
        '',
        TaliaIcons.hifz,
      ),
      AdultJourneyLaunchKind.azkar => (
        l10n.adultJourneyOpenAzkar,
        '',
        TaliaIcons.azkar,
      ),
      _ => (l10n.adultJourneyOpenReading, '', TaliaIcons.mushaf),
    };
  }
}
