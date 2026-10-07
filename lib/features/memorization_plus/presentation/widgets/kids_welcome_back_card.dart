import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

/// K33 — a warm welcome after three or more days away. It never mentions a
/// lost streak; the mission below starts with an easy, familiar step.
class KidsWelcomeBackCard extends StatelessWidget {
  const KidsWelcomeBackCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('kids-welcome-back-card'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: KidsTheme.goldStar.withValues(alpha: 0.14),
        borderRadius: KidsTheme.cardRadius,
        border: Border.all(color: KidsTheme.goldStar.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const TaliaIcon(
            TaliaKidsIcons.wave,
            color: KidsTheme.goldStar,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.kidsWelcomeBackTitle,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.kidsWelcomeBackSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
