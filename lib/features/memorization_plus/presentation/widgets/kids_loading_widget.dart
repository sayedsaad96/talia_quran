import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';
import '../world/kids_world_palette.dart';
import 'kids_chunky_button.dart';

/// Gamified Loading Widget for Kids Mode
class KidsLoadingWidget extends StatelessWidget {
  const KidsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(color: KidsTheme.goldStar),
                TaliaIcon(
                  TaliaKidsIcons.starFilled,
                  size: 24,
                  color: KidsTheme.goldStar,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.kidsPreparing,
            style: AppTypography.titleSmall.copyWith(
              fontFamily: 'Amiri',
              color: KidsWorldPalette.of(context).onScene,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gamified Error Widget for Kids Mode
class KidsErrorWidget extends StatelessWidget {
  const KidsErrorWidget({
    super.key,
    required this.onRetry,
    this.message,
    this.actionLabel,
  });

  final VoidCallback onRetry;

  /// Label for the action button; defaults to "Try again". A state that a
  /// retry cannot fix (e.g. the daily limit) passes "Go back" instead.
  final String? actionLabel;

  /// Optional specific (already localized) message; when null a generic
  /// child-friendly text is shown instead of raw failure details.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TaliaIcon(
            TaliaKidsIcons.home,
            size: 64,
            color: KidsTheme.goldStar,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message ?? context.l10n.kidsUnexpectedError,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontFamily: 'Amiri',
              color: KidsWorldPalette.of(context).onScene,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          KidsChunkyButton(
            onPressed: onRetry,
            icon: TaliaKidsIcons.refresh,
            label: actionLabel ?? context.l10n.tryAgain,
            tone: KidsButtonTone.gold,
            height: 56,
          ),
        ],
      ),
    );
  }
}
