import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_home_mission.dart';
import '../theme/kids_theme.dart';

/// One mission from the guardian in «كنوزي». A new mission offers "I did
/// it!"; a reported one waits for the guardian to see it.
class KidsHomeMissionCard extends StatelessWidget {
  const KidsHomeMissionCard({super.key, required this.mission, this.onReport});

  final KidsHomeMission mission;

  /// Null hides the report button (for example while it is being sent).
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isNew = mission.status == KidsHomeMissionStatus.assigned;
    return Container(
      key: ValueKey('kids-home-mission-${mission.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: KidsTheme.parchmentGradient,
        borderRadius: KidsTheme.cardRadius,
        border: Border.all(color: KidsTheme.parchmentEdge, width: 1.5),
        boxShadow: KidsTheme.card25DShadow,
      ),
      child: Row(
        children: [
          TaliaIcon(
            isNew ? TaliaKidsIcons.home : TaliaKidsIcons.hourglass,
            color: KidsTheme.houseBrown,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isNew
                      ? l10n.kidsHomeMissionNew
                      : l10n.kidsHomeMissionWaitingGuardian,
                  style: AppTypography.bodySmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          if (isNew && onReport != null) ...[
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              key: ValueKey('kids-home-mission-report-${mission.id}'),
              onPressed: onReport,
              style: FilledButton.styleFrom(
                backgroundColor: KidsTheme.goldStar,
                foregroundColor: KidsTheme.inkOnParchment,
              ),
              child: Text(l10n.kidsHomeMissionReportAction),
            ),
          ],
        ],
      ),
    );
  }
}
