import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/kids_daily_missions.dart';
import '../theme/kids_theme.dart';

/// One non-learning card of «مهماتي اليوم» (e.g. read a page of the Mushaf).
/// Opaque cream card; a done chip once completed, a chevron otherwise.
class KidsDailyMissionTile extends StatelessWidget {
  const KidsDailyMissionTile({
    super.key,
    required this.mission,
    required this.onTap,
  });

  final KidsDailyMission mission;
  final VoidCallback onTap;

  bool get _done => mission.status == KidsDailyMissionStatus.completed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (mission.kind) {
      KidsDailyMissionKind.reading => l10n.kidsReadingMissionTitle,
      _ => l10n.kidsDailyMissionsTitle,
    };
    final icon = switch (mission.kind) {
      KidsDailyMissionKind.reading => Icons.menu_book_rounded,
      _ => Icons.flag_rounded,
    };
    return Semantics(
      button: true,
      label: _done ? '$title, ${l10n.kidsMissionDone}' : title,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: KidsTheme.creamParchment,
        shape: const RoundedRectangleBorder(
          borderRadius: KidsTheme.cardRadius,
          side: BorderSide(color: KidsTheme.parchmentEdge),
        ),
        child: InkWell(
          borderRadius: KidsTheme.cardRadius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: _done
                        ? KidsTheme.successGreen
                        : KidsTheme.houseBrown,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: KidsTheme.inkOnParchment,
                        fontFamily: 'Amiri',
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (_done)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: KidsTheme.successGreen.withValues(alpha: 0.15),
                        borderRadius: KidsTheme.buttonRadius,
                      ),
                      child: Text(
                        l10n.kidsMissionDone,
                        style: AppTypography.labelLarge.copyWith(
                          color: KidsTheme.inkOnParchment,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: KidsTheme.houseBrown,
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
