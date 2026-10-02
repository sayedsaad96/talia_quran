import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

/// Quick routes for the kids home, kept in the scroll content so they are
/// discovered with the day's learning activity instead of competing with it.
class KidsHomeNavigationCards extends StatelessWidget {
  const KidsHomeNavigationCards({
    super.key,
    required this.onMushafTap,
    required this.onJourneyTap,
    required this.onMissionTap,
  });

  final VoidCallback onMushafTap;
  final VoidCallback onJourneyTap;
  final VoidCallback onMissionTap;

  @override
  Widget build(BuildContext context) {
    final mushaf = _KidsHomeNavigationCard(
      key: const ValueKey('kids-home-action-mushaf'),
      icon: Icons.menu_book_rounded,
      label: context.l10n.kidsGamifiedMushaf,
      onTap: onMushafTap,
    );
    final journey = _KidsHomeNavigationCard(
      key: const ValueKey('kids-home-action-journey'),
      icon: Icons.map_rounded,
      label: context.l10n.kidsGamifiedJourney,
      onTap: onJourneyTap,
    );
    final missions = _KidsHomeNavigationCard(
      key: const ValueKey('kids-home-action-missions'),
      icon: Icons.flag_rounded,
      label: context.l10n.kidsGamifiedMissions,
      onTap: onMissionTap,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final columns = constraints.maxWidth >= 260 && textScale <= 1
            ? 3
            : constraints.maxWidth >= 180 && textScale <= 1.5
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1,
          children: [mushaf, journey, missions],
        );
      },
    );
  }
}

class _KidsHomeNavigationCard extends StatelessWidget {
  const _KidsHomeNavigationCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: KidsTheme.forestGreen, size: 28),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleSmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
