import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import 'home_prayer_times_sheet.dart';

/// Clarity mode's home: three large, labelled actions in place of the hero
/// and its cards. Next prayer appears only once prayer times are known.
class HomeClarityActions extends StatelessWidget {
  const HomeClarityActions({super.key, required this.state, required this.skin});

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final continueRoute = state.continueRecitation?.route ?? AppRoutes.quran;
    final snapshot = state.prayerSnapshot;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ClarityButton(
            key: const ValueKey('home_clarity_continue'),
            icon: TaliaIcons.reading,
            label: l10n.clarityContinueReading,
            skin: skin,
            onPressed: () => context.push(continueRoute),
          ),
          const SizedBox(height: AppSpacing.md),
          _ClarityButton(
            key: const ValueKey('home_clarity_review'),
            icon: TaliaIcons.history,
            label: l10n.clarityTodayReview,
            skin: skin,
            onPressed: () => context.push(AppRoutes.memorizationHub),
          ),
          if (snapshot != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ClarityButton(
              key: const ValueKey('home_clarity_prayer'),
              icon: TaliaIcons.bell,
              label: l10n.clarityNextPrayer(
                snapshot.nextName,
                MaterialLocalizations.of(context).formatTimeOfDay(
                  TimeOfDay.fromDateTime(snapshot.nextTime.toLocal()),
                ),
              ),
              skin: skin,
              onPressed: () => showHomePrayerTimesSheet(
                context,
                snapshot: snapshot,
                hijriLabel: state.hijriLabel,
                skin: skin,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClarityButton extends StatelessWidget {
  const _ClarityButton({
    super.key,
    required this.icon,
    required this.label,
    required this.skin,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final HomeSkin skin;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: skin.accent,
      foregroundColor: Colors.white,
      // Well above the 48dp minimum; the label may wrap at large text sizes.
      minimumSize: const Size.fromHeight(72),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      alignment: AlignmentDirectional.centerStart,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    ),
    icon: Icon(icon, size: 28),
    label: Text(
      label,
      style: AppTypography.titleMedium.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
