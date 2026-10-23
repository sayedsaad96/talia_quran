import '../../../core/l10n/app_localizations.dart';

String localizedGroupKhatmahError(AppLocalizations l10n, String code) =>
    switch (code) {
      'conflict' => l10n.groupKhatmahConflict,
      'network' => l10n.groupKhatmahNetwork,
      'not_member' || 'gone' => l10n.groupKhatmahNotMember,
      'not_eligible' => l10n.groupKhatmahNotEligible,
      'group_full' => l10n.groupKhatmahFull,
      'invalid_invite' => l10n.groupKhatmahInvalidInvite,
      'rate_limited' => l10n.groupKhatmahRateLimited,
      'owner_has_members' => l10n.groupKhatmahOwnerHasMembers,
      'recovery_required' => l10n.groupKhatmahRecoveryRequired,
      _ => l10n.groupKhatmahError,
    };
