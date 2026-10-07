import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
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
        TaliaIcons.checkCircleFilled,
      ),
      PrayerCompanionStatus.prayNow => (
        l10n.prayerCompanionStatusPrayNow,
        TaliaIcons.playCircle,
      ),
      PrayerCompanionStatus.remindLater => (
        l10n.prayerCompanionStatusRemindLater,
        TaliaIcons.bell,
      ),
      PrayerCompanionStatus.notYet => (
        l10n.prayerCompanionStatusNotYet,
        TaliaIcons.hourglass,
      ),
      PrayerCompanionStatus.unconfirmed when isPast => (
        l10n.prayerCompanionStatusUnconfirmedPast,
        TaliaIcons.circle,
      ),
      PrayerCompanionStatus.unconfirmed => (
        l10n.prayerCompanionStatusUpcoming,
        TaliaIcons.clock,
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
