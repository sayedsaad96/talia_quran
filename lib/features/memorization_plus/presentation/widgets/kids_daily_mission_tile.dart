import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/kids_daily_missions.dart';
import '../theme/kids_theme.dart';
import 'kids_chunky_button.dart';

/// One non-learning card of «مهماتي اليوم» (e.g. read a page of the Mushaf).
/// Opaque cream card; a done chip once completed, a chevron otherwise.
class KidsDailyMissionTile extends StatelessWidget {
  const KidsDailyMissionTile({
    super.key,
    required this.mission,
    required this.onTap,
    this.onReport,
  });

  final KidsDailyMission mission;
  final VoidCallback onTap;

  /// «أنجزتها!» for a `home` mission that is not reported yet.
  final VoidCallback? onReport;

  bool get _done => mission.status == KidsDailyMissionStatus.completed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (mission.kind) {
      KidsDailyMissionKind.reading => l10n.kidsReadingMissionTitle,
      KidsDailyMissionKind.home =>
        mission.homeMissionTitle ?? l10n.kidsDailyMissionsTitle,
      _ => l10n.kidsDailyMissionsTitle,
    };
    final icon = switch (mission.kind) {
      KidsDailyMissionKind.reading => Icons.menu_book_rounded,
      KidsDailyMissionKind.home => Icons.home_rounded,
      _ => Icons.flag_rounded,
    };
    if (mission.kind == KidsDailyMissionKind.home) {
      return _buildHome(context, title, icon);
    }
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

  /// The guardian's home mission: title plus «أنجزتها!» until reported. Not
  /// tappable as a whole; the only action is the report button.
  Widget _buildHome(BuildContext context, String title, IconData icon) {
    final l10n = context.l10n;
    return Material(
      color: KidsTheme.creamParchment,
      shape: const RoundedRectangleBorder(
        borderRadius: KidsTheme.cardRadius,
        side: BorderSide(color: KidsTheme.parchmentEdge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                    child: Semantics(
                      label: _done ? '$title, ${l10n.kidsMissionDone}' : title,
                      excludeSemantics: true,
                      child: Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: KidsTheme.inkOnParchment,
                          fontFamily: 'Amiri',
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  if (_done) ...[
                    const SizedBox(width: AppSpacing.sm),
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
                    ),
                  ],
                ],
              ),
              if (!_done && onReport != null) ...[
                const SizedBox(height: AppSpacing.sm),
                KidsChunkyButton(
                  key: const ValueKey('kids-home-mission-report'),
                  label: l10n.kidsHomeMissionReportAction,
                  icon: Icons.check_rounded,
                  height: 56,
                  onPressed: onReport,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
