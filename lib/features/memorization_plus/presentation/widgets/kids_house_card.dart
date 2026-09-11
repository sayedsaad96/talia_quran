import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';

/// 2.5D gamified destination stop representing a Quran memorization house
/// along the adventure path.
class KidsHouseCard extends StatelessWidget {
  const KidsHouseCard({
    super.key,
    required this.stage,
    this.surahName,
    this.onTap,
    this.onLockedTap,
    this.width = 172,
  });

  final KidsJourneyStage stage;
  final String? surahName;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;
  final double width;

  bool get _isLocked => stage.status == KidsJourneyStageStatus.locked;
  bool get _isCurrent => stage.status == KidsJourneyStageStatus.current;
  bool get _isCompleted => stage.status == KidsJourneyStageStatus.completed;
  bool get _isReview => stage.status == KidsJourneyStageStatus.needsReview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    final title = _isReview
        ? l10n.kidsGamifiedReviewHouseTitle(stage.stageNumber)
        : l10n.kidsGamifiedHouseTitle(stage.stageNumber);

    final visualStars = _calculateVisualStars(stage);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLocked ? onLockedTap : onTap,
          borderRadius: KidsTheme.cardRadius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Destination Building Landmark with 2.5D stage number badge
              _DestinationLandmark(
                status: stage.status,
                stageNumber: stage.stageNumber,
                isCurrent: _isCurrent,
                isLocked: _isLocked,
                isCompleted: _isCompleted,
                reducedMotion: reducedMotion,
              ),

              const SizedBox(height: 6),

              // 2. 2.5D Destination Plaque / Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: _plaqueGradient(stage.status),
                  borderRadius: KidsTheme.cardRadius,
                  border: Border.all(
                    color: _plaqueBorderColor(stage.status),
                    width: _isCurrent ? 2.5 : 1.5,
                  ),
                  boxShadow: _plaqueShadows(stage.status),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // House Title (Crucial for existing tests and clarity)
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: _textColor(stage.status),
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                      ),
                    ),

                    if (surahName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        surahName!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: _secondaryTextColor(stage.status),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],

                    const SizedBox(height: 2),
                    Text(
                      l10n.kidsGamifiedAyahRange(
                        stage.startAyah,
                        stage.endAyah,
                      ),
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall.copyWith(
                        color: _secondaryTextColor(stage.status),
                        letterSpacing: 0,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Progress track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: stage.progress.clamp(0, 1).toDouble(),
                        backgroundColor: Colors.black.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _progressColor(stage.status),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Progress Ayah Count
                    Text(
                      l10n.kidsGamifiedProgressCount(
                        stage.completedCount,
                        stage.totalAyahs,
                      ),
                      style: AppTypography.labelSmall.copyWith(
                        color: _secondaryTextColor(stage.status),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Visual Journey Progress Stars (derived strictly from stage progress)
                    _JourneyStarsRow(
                      earnedStars: visualStars,
                      isLocked: _isLocked,
                    ),

                    const SizedBox(height: 8),

                    // Actionable CTA or Status Indicator
                    _DestinationActionFooter(
                      status: stage.status,
                      onTap: _isLocked ? onLockedTap : onTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Calculates visual progress stars (0 to 3) strictly representing
  /// advance through the current stage, never quality or mastery grading.
  static int _calculateVisualStars(KidsJourneyStage stage) {
    if (stage.status == KidsJourneyStageStatus.locked) {
      return 0;
    }
    if (stage.status == KidsJourneyStageStatus.completed) {
      return 3;
    }
    if (stage.status == KidsJourneyStageStatus.needsReview) {
      return 2;
    }
    // current stage
    if (stage.progress >= 0.6) {
      return 2;
    }
    if (stage.progress > 0) {
      return 1;
    }
    return 0;
  }

  static LinearGradient _plaqueGradient(KidsJourneyStageStatus status) {
    return switch (status) {
      KidsJourneyStageStatus.current => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F7D6B),
            Color(0xFF074D40),
          ],
        ),
      KidsJourneyStageStatus.completed => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF9E6),
            Color(0xFFFDE8B5),
          ],
        ),
      KidsJourneyStageStatus.needsReview => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6B21A8),
            Color(0xFF4C1D95),
          ],
        ),
      KidsJourneyStageStatus.locked => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF374151),
            Color(0xFF1F2937),
          ],
        ),
    };
  }

  static Color _plaqueBorderColor(KidsJourneyStageStatus status) {
    return switch (status) {
      KidsJourneyStageStatus.current => KidsTheme.mintGlow,
      KidsJourneyStageStatus.completed => KidsTheme.goldStar,
      KidsJourneyStageStatus.needsReview => const Color(0xFFC084FC),
      KidsJourneyStageStatus.locked => const Color(0xFF4B5563),
    };
  }

  static List<BoxShadow> _plaqueShadows(KidsJourneyStageStatus status) {
    if (status == KidsJourneyStageStatus.current) {
      return KidsTheme.nodeGlowCurrentShadow;
    }
    return KidsTheme.card25DShadow;
  }

  static Color _textColor(KidsJourneyStageStatus status) {
    if (status == KidsJourneyStageStatus.completed) {
      return const Color(0xFF1F2937);
    }
    return Colors.white;
  }

  static Color _secondaryTextColor(KidsJourneyStageStatus status) {
    if (status == KidsJourneyStageStatus.completed) {
      return const Color(0xFF4B5563);
    }
    return Colors.white.withValues(alpha: 0.85);
  }

  static Color _progressColor(KidsJourneyStageStatus status) {
    return switch (status) {
      KidsJourneyStageStatus.completed => KidsTheme.forestGreen,
      KidsJourneyStageStatus.current => KidsTheme.goldStar,
      KidsJourneyStageStatus.needsReview => const Color(0xFFFBBF24),
      KidsJourneyStageStatus.locked => Colors.grey.shade600,
    };
  }
}

/// The 3D Destination Building Landmark with a floating stage badge
class _DestinationLandmark extends StatelessWidget {
  const _DestinationLandmark({
    required this.status,
    required this.stageNumber,
    required this.isCurrent,
    required this.isLocked,
    required this.isCompleted,
    required this.reducedMotion,
  });

  final KidsJourneyStageStatus status;
  final int stageNumber;
  final bool isCurrent;
  final bool isLocked;
  final bool isCompleted;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final asset = switch (status) {
      KidsJourneyStageStatus.locked => KidsTheme.houseLockedAsset,
      KidsJourneyStageStatus.current => KidsTheme.houseCurrentAsset,
      KidsJourneyStageStatus.completed => KidsTheme.houseCompletedAsset,
      KidsJourneyStageStatus.needsReview => KidsTheme.houseReviewAsset,
    };

    Widget buildingImage = Image.asset(
      asset,
      width: 96,
      height: 96,
      fit: BoxFit.contain,
    );

    if (isLocked) {
      // Gentle desaturation for locked building
      buildingImage = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0.33, 0.33, 0.33, 0, 0,
          0,    0,    0,    0.85, 0,
        ]),
        child: buildingImage,
      );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Glow aura for current stage
        if (isCurrent)
          RepaintBoundary(
            child: Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x991ABC9C),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: Color(0x66F59E0B),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

        // Building
        buildingImage,

        // Floating Stage Number Badge at the top corner
        Positioned(
          top: -2,
          right: 0,
          child: _StageNumberBadge(
            stageNumber: stageNumber,
            status: status,
          ),
        ),

        // Padlock icon if locked
        if (isLocked)
          const Positioned(
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xCC1F2937),
              child: Icon(
                Icons.lock_rounded,
                color: Color(0xFFE5C07B),
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}

/// Stage number badge with 2.5D beveled appearance
class _StageNumberBadge extends StatelessWidget {
  const _StageNumberBadge({
    required this.stageNumber,
    required this.status,
  });

  final int stageNumber;
  final KidsJourneyStageStatus status;

  @override
  Widget build(BuildContext context) {
    final bgColor = switch (status) {
      KidsJourneyStageStatus.current => KidsTheme.mintGlow,
      KidsJourneyStageStatus.completed => KidsTheme.goldStar,
      KidsJourneyStageStatus.needsReview => const Color(0xFFA855F7),
      KidsJourneyStageStatus.locked => const Color(0xFF4B5563),
    };

    final textColor = status == KidsJourneyStageStatus.completed
        ? const Color(0xFF1F2937)
        : Colors.white;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$stageNumber',
        style: AppTypography.labelMedium.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// 3-Star visual journey progress indicator
class _JourneyStarsRow extends StatelessWidget {
  const _JourneyStarsRow({
    required this.earnedStars,
    required this.isLocked,
  });

  final int earnedStars;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isFilled = !isLocked && index < earnedStars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 20,
            color: isFilled
                ? KidsTheme.goldStar
                : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}

/// Action footer on the destination card
class _DestinationActionFooter extends StatelessWidget {
  const _DestinationActionFooter({
    required this.status,
    required this.onTap,
  });

  final KidsJourneyStageStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (status == KidsJourneyStageStatus.current) {
      return SizedBox(
        width: double.infinity,
        height: 36,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(
            l10n.kidsGamifiedStartMission,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: KidsTheme.goldStar,
            foregroundColor: const Color(0xFF1F2937),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            elevation: 3,
          ),
        ),
      );
    }

    if (status == KidsJourneyStageStatus.needsReview) {
      return SizedBox(
        width: double.infinity,
        height: 36,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            l10n.kidsGamifiedContinueNow,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC084FC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            elevation: 3,
          ),
        ),
      );
    }

    if (status == KidsJourneyStageStatus.completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x3310B981),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Color(0xFF059669),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l10n.kidsGamifiedCompletedStage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: const Color(0xFF065F46),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Locked status
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_rounded,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.kidsGamifiedLockedStage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
