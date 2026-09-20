import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../domain/entities/prayer_companion.dart';

/// Compact, accessible status chip for one obligatory prayer row in the
/// prayer-times sheet.
///
/// Every state carries visible text AND a semantic label — color is never
/// the only signal. A status is derived from the user's explicit record or
/// the prayer's position relative to now; a checkmark is NEVER inferred
/// merely because time has passed.
class PrayerCompanionStatusWidget extends StatelessWidget {
  const PrayerCompanionStatusWidget({
    super.key,
    required this.status,
    required this.isPast,
    required this.prayerName,
    required this.skin,
  });

  final PrayerCompanionStatus status;

  /// Whether the prayer time has passed. `unconfirmed` only gets the
  /// "not confirmed yet" label for past prayers; upcoming unconfirmed
  /// prayers show the neutral upcoming label instead.
  final bool isPast;
  final String prayerName;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, icon) = switch (status) {
      PrayerCompanionStatus.confirmed => (
        l10n.prayerCompanionStatusConfirmed,
        Icons.check_circle_rounded,
      ),
      PrayerCompanionStatus.prayNow => (
        l10n.prayerCompanionStatusPrayNow,
        Icons.play_circle_outline_rounded,
      ),
      PrayerCompanionStatus.remindLater => (
        l10n.prayerCompanionStatusRemindLater,
        Icons.notifications_active_outlined,
      ),
      PrayerCompanionStatus.notYet => (
        l10n.prayerCompanionStatusNotYet,
        Icons.hourglass_empty_rounded,
      ),
      PrayerCompanionStatus.unconfirmed when isPast => (
        l10n.prayerCompanionStatusUnconfirmedPast,
        Icons.circle_outlined,
      ),
      PrayerCompanionStatus.unconfirmed => (
        l10n.prayerCompanionStatusUpcoming,
        Icons.schedule_rounded,
      ),
    };
    final color = status == PrayerCompanionStatus.confirmed
        ? skin.gold
        : skin.textSecondary;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.prayerCompanionRowSemantics(prayerName, label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: status == PrayerCompanionStatus.confirmed
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
