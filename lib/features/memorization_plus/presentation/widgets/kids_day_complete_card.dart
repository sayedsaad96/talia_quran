import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

/// N3 — the kids home card once today's new-ayah quota is used up. It
/// replaces a mission the session gate would refuse with a calm, encouraging
/// end of the day; the bigger confetti moment stays reserved for finishing
/// the whole journey.
class KidsDayCompleteCard extends StatelessWidget {
  const KidsDayCompleteCard({super.key, required this.dailyGoalCap});

  /// Today's new-ayah quota from the age-band policy.
  final int dailyGoalCap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: KidsTheme.kidsCardGradient,
        borderRadius: KidsTheme.cardRadius,
        border: Border.all(color: KidsTheme.goldStar.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.nights_stay_rounded,
            color: KidsTheme.goldStar,
            size: 64,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.kidsGamifiedDailyLimitReached(dailyGoalCap),
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: KidsTheme.shellTextPrimary,
              fontFamily: 'Amiri',
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
