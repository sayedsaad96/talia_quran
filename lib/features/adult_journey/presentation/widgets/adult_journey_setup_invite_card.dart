import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../../home/presentation/widgets/glass_panel.dart';
import '../cubits/adult_journey_state.dart';
import 'adult_journey_error_text.dart';

/// The non-blocking invitation to personalize. «لاحقًا» hides it for the
/// local day only; the setup stays available from Settings.
class AdultJourneySetupInviteCard extends StatelessWidget {
  const AdultJourneySetupInviteCard({
    super.key,
    required this.skin,
    required this.onPersonalize,
    required this.onLater,
    this.error,
  });

  final HomeSkin skin;
  final VoidCallback onPersonalize;
  final VoidCallback onLater;

  /// A failed «لاحقًا» snooze; shown here, where the action was taken.
  final AdultJourneyErrorCode? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassPanel(
      skin: skin,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.adultJourneyInviteTitle,
            style: AppTypography.titleMedium.copyWith(
              color: skin.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.adultJourneyInviteBody,
            style: AppTypography.bodyMedium.copyWith(
              color: skin.textSecondary,
              height: 1.5,
            ),
          ),
          if (error case final code?)
            AdultJourneyErrorText(
              code,
              key: const ValueKey('adult_invite_error'),
            ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TextButton(
                key: const ValueKey('adult_invite_later'),
                onPressed: onLater,
                child: Text(l10n.adultJourneyInviteLater),
              ),
              FilledButton(
                key: const ValueKey('adult_invite_personalize'),
                onPressed: onPersonalize,
                child: Text(l10n.adultJourneyInviteAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
