import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/usecases/guardian_unlink_usecase.dart';
import 'guardian_pin_dialog.dart';

/// Kids settings entry for a linked child to end the guardian link.
class GuardianUnlinkTile extends StatelessWidget {
  const GuardianUnlinkTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const ValueKey('kids-unlink-guardian'),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.link_off_rounded, color: AppColors.error),
      ),
      title: Text(
        context.l10n.guardianUnlinkTileTitle,
        style: AppTypography.bodyMedium.copyWith(
          color: context.tokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        context.l10n.guardianUnlinkTileSubtitle,
        style: AppTypography.labelSmall.copyWith(
          color: context.tokens.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Explains what ends, asks for the guardian PIN (or its recovery), then
/// revokes the link on the server before changing anything locally.
Future<void> runGuardianUnlink(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.guardianUnlinkConfirmTitle),
      content: Text(dialogContext.l10n.guardianUnlinkConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(dialogContext.l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('kids-unlink-guardian-confirm'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(dialogContext.l10n.guardianUnlinkAction),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final verified = await verifyGuardianPin(
    context,
    confirmLabel: context.l10n.guardianUnlinkAction,
    allowRecovery: true,
  );
  if (!verified || !context.mounted) return;
  final result = await getIt<UnlinkGuardianUsecase>()();
  if (!context.mounted) return;
  final message = result.fold(
    (failure) => context.localizedCubitMessage(failure.message),
    (_) => context.l10n.guardianUnlinkDone,
  );
  if (result.isRight()) getIt<MemorizationPathResolver>().notifyChanged();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
