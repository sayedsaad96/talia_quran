import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';
import 'kids_chunky_button.dart';
import 'kids_name_ribbon.dart';

import '../../../../core/utils/locale_number_formatter.dart';

class KidsMissionCard extends StatelessWidget {
  const KidsMissionCard({
    super.key,
    required this.stage,
    this.surahName,
    this.onContinue,
    this.isReviewMission = false,
    this.reviewAyahs,
    this.childName,
  });

  final KidsJourneyStage? stage;
  final String? surahName;

  /// The child's name, shown on the banner ribbon. Without it the card keeps
  /// the generic Talia ribbon image.
  final String? childName;
  final VoidCallback? onContinue;

  /// Whether the resolved next mission is a review task (due SRS review or
  /// linked stage review) rather than new memorization, so the card titles it
  /// "Ready for review" instead of "Last mission".
  final bool isReviewMission;

  /// Ayahs the review mission actually opens. A due SRS review can target a
  /// finished stage, so the card describes these ayahs instead of the
  /// current memorization stage's range and progress (N7).
  final List<int>? reviewAyahs;

  @override
  Widget build(BuildContext context) {
    final currentStage = stage;
    final missionAyahs = isReviewMission ? reviewAyahs : null;
    final title = missionAyahs != null && missionAyahs.isNotEmpty
        ? (surahName ?? context.l10n.kidsGamifiedNeedsReview)
        : currentStage == null
        ? context.l10n.kidsStartFirstStageToday
        : context.l10n.kidsGamifiedHouseTitle(
            LocaleNumberFormatter.format(
              (currentStage.stageNumber).toString(),
              context.l10n.localeName,
            ),
          );
    final subtitle = missionAyahs != null && missionAyahs.isNotEmpty
        ? context.l10n.kidsGamifiedAyahRange(
            LocaleNumberFormatter.format(
              (missionAyahs.first).toString(),
              context.l10n.localeName,
            ),
            LocaleNumberFormatter.format(
              (missionAyahs.last).toString(),
              context.l10n.localeName,
            ),
          )
        : currentStage == null
        ? context.l10n.kidsFirstMissionSubtitle
        : [
            // ignore: use_null_aware_elements
            if (surahName != null) surahName!,
            context.l10n.kidsGamifiedAyahRange(
              LocaleNumberFormatter.format(
                (currentStage.startAyah).toString(),
                context.l10n.localeName,
              ),
              LocaleNumberFormatter.format(
                (currentStage.endAyah).toString(),
                context.l10n.localeName,
              ),
            ),
            context.l10n.kidsGamifiedProgressCount(
              LocaleNumberFormatter.format(
                (currentStage.completedCount).toString(),
                context.l10n.localeName,
              ),
              LocaleNumberFormatter.format(
                (currentStage.totalAyahs).toString(),
                context.l10n.localeName,
              ),
            ),
          ].join(' • ');

    final name = childName?.trim();
    final Widget banner = name == null || name.isEmpty
        ? Image.asset(
            KidsTheme.ribbonBannerAsset,
            width: 64,
            height: 64,
            fit: BoxFit.contain,
          )
        : KidsNameRibbon(name: name);

    final missionText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // Review missions (due SRS or linked review) are today's task, not
          // yesterday's — never label a due review as the "last" mission.
          isReviewMission
              ? context.l10n.kidsGamifiedNeedsReview
              : context.l10n.kidsGamifiedLastMission,
          style: AppTypography.labelMedium.copyWith(
            color: isReviewMission
                ? KidsTheme.reviewPurple
                : KidsTheme.forestGreen,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleLarge.copyWith(
            color: KidsTheme.nightSkyDark,
            fontFamily: 'Amiri',
            letterSpacing: 0,
          ),
        ),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: KidsTheme.nightSkyMid.withValues(alpha: 0.72),
            letterSpacing: 0,
          ),
        ),
      ],
    );

    final continueButton = KidsChunkyButton(
      onPressed: onContinue,
      icon: TaliaKidsIcons.play,
      label: context.l10n.kidsGamifiedContinueNow,
      maxLines: 1,
    );

    final actionButton = continueButton;

    final cardContainer = Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: KidsTheme.creamParchment,
        borderRadius: KidsTheme.cardRadius,
        border: Border.all(color: KidsTheme.parchmentEdge, width: 2),
        boxShadow: [
          BoxShadow(
            color: KidsTheme.goldWarm.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              banner,
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: missionText),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          actionButton,
        ],
      ),
    );

    return cardContainer;
  }
}
