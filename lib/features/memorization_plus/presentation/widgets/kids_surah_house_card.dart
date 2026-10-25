import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icon.dart';
import '../../../../core/icons/talia_icon_data.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/kids_quran_map_visuals.dart';
import '../../domain/services/kids_surah_house_summary_builder.dart';
import '../theme/kids_theme.dart';

/// One surah house on the Quran journey map: a parchment card with the
/// surah name, ayah count, progress bar, three stars and a circular status
/// ring on the far edge.
class KidsSurahHouseCard extends StatelessWidget {
  const KidsSurahHouseCard({
    super.key,
    required this.house,
    required this.name,
    required this.isCurrent,
    required this.onTap,
    this.popStars = false,
  });

  final KidsSurahHouse house;
  final String name;
  final bool isCurrent;
  final VoidCallback onTap;

  /// Whether the filled stars should pop in one by one (the celebration of a
  /// surah completed since the last visit). Declared here so the card owns
  /// its celebration visuals; the pop animation is wired by the journey map
  /// when the Talia overlay lands.
  final bool popStars;

  static IconData _glyph(KidsSurahHouseStatus status) => switch (status) {
    KidsSurahHouseStatus.completed => TaliaKidsIcons.starFilled,
    KidsSurahHouseStatus.needsReview => TaliaKidsIcons.refresh,
    KidsSurahHouseStatus.inProgress => TaliaKidsIcons.reading,
    KidsSurahHouseStatus.notStarted => TaliaKidsIcons.lock,
  };

  static Color _color(KidsSurahHouseStatus status) => switch (status) {
    KidsSurahHouseStatus.completed => KidsTheme.successGreen,
    KidsSurahHouseStatus.needsReview => KidsTheme.reviewPurple,
    KidsSurahHouseStatus.inProgress => KidsTheme.goldStar,
    KidsSurahHouseStatus.notStarted => KidsTheme.lockedGrey,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final countText = l10n.countAyahs(
      house.ayahCount,
      context.numText(house.ayahCount),
    );
    final statusColor = _color(house.status);
    final statusText = switch (house.status) {
      KidsSurahHouseStatus.completed => l10n.kidsHouseStatusCompleted,
      KidsSurahHouseStatus.needsReview => l10n.kidsHouseStatusNeedsReview,
      KidsSurahHouseStatus.inProgress => l10n.kidsHouseStatusInProgress,
      KidsSurahHouseStatus.notStarted => l10n.kidsHouseStatusNotStarted,
    };
    final stars = kidsSurahStars(house);
    final starsLabel = l10n.kidsHouseStarsLabel(
      context.numText(stars),
      context.numText(3),
    );
    return Semantics(
      button: true,
      container: true,
      label: [
        name,
        countText,
        statusText,
        starsLabel,
        if (isCurrent) l10n.kidsHouseCurrentMarker,
      ].join('. '),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: KidsTheme.cardRadius,
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                gradient: KidsTheme.parchmentGradient,
                borderRadius: KidsTheme.cardRadius,
                border: Border.all(
                  color: isCurrent
                      ? KidsTheme.goldStar
                      : KidsTheme.parchmentEdge,
                  width: isCurrent ? 3 : 2.5,
                ),
                boxShadow: [
                  ...KidsTheme.card25DShadow,
                  if (isCurrent) ...KidsTheme.goldGlow,
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: KidsTheme.inkOnParchment,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                countText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: KidsTheme.inkOnParchment,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _StarRow(
                              stars: stars,
                              surahId: house.surahId,
                              popStars: popStars,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXs,
                          ),
                          child: LinearProgressIndicator(
                            value: house.progress.clamp(0.0, 1.0),
                            minHeight: 6,
                            color: statusColor,
                            backgroundColor: KidsTheme.parchmentEdge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusRing(
                    key: ValueKey('kids-quran-ring-${house.surahId}'),
                    status: house.status,
                    progress: house.progress,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three progress stars of a house card: gold when earned, faded
/// parchment when not.
class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.stars,
    required this.surahId,
    required this.popStars,
  });

  final int stars;
  final int surahId;
  final bool popStars;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey('kids-quran-stars-$surahId'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          TaliaIcon(
            i < stars ? TaliaKidsIcons.starFilled : TaliaKidsIcons.star,
            color: i < stars ? KidsTheme.goldStar : KidsTheme.parchmentEdge,
            size: 14,
          ),
      ],
    );
  }
}

/// The circular status ring on the card's far edge: a progress ring holding
/// the status glyph (star when completed, lock when not started, refresh
/// when a review is due, book while in progress).
class _StatusRing extends StatelessWidget {
  const _StatusRing({super.key, required this.status, required this.progress});

  final KidsSurahHouseStatus status;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      KidsSurahHouseStatus.completed => KidsTheme.successGreen,
      KidsSurahHouseStatus.needsReview => KidsTheme.reviewPurple,
      KidsSurahHouseStatus.inProgress => KidsTheme.goldStar,
      KidsSurahHouseStatus.notStarted => KidsTheme.lockedGrey,
    };
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: KidsTheme.parchmentEdge,
            ),
          ),
          TaliaIcon(KidsSurahHouseCard._glyph(status), color: color, size: 22),
        ],
      ),
    );
  }
}
