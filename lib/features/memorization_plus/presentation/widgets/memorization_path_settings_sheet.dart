import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/guardian_session_controller.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import 'guardian_pin_dialog.dart';
import 'guardian_unlink_tile.dart';

Future<void> showMemorizationPathSettingsSheet(
  BuildContext context, {
  required bool isDark,
  String replacementLocation = AppRoutes.memorizationPlus,
}) async {
  // A child who skipped guardian linking at setup can link later from here;
  // a linked child or an adult never sees the option.
  final profile =
      (await getIt<MemorizationPlusRepository>().getMemorizationProfile()).fold(
        (_) => null,
        (profile) => profile,
      );
  final canLinkGuardian =
      profile != null && profile.isChild && !profile.isGuardianLinked;
  // A linked child's guardian manages from their own account and device. The
  // area is offered even before a PIN exists; opening it creates one.
  final canOpenGuardianArea = canLinkGuardian;
  if (!context.mounted) return;
  final returnLocation = _currentLocation(context);
  // A second tap on a tile would pop the page under the sheet and run the
  // guardian flow twice.
  var tileActionStarted = false;
  bool startTileAction() {
    if (tileActionStarted) return false;
    tileActionStarted = true;
    return true;
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.tokens.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctx.l10n.changeMemorizationPath,
              style: AppTypography.headlineSmall.copyWith(
                color: context.tokens.textPrimary,
                fontFamily: 'Amiri',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(TaliaIcons.replay, color: AppColors.warning),
              ),
              title: Text(
                ctx.l10n.resetMemorizationPathTileTitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                ctx.l10n.resetMemorizationPathPreserveProgressDesc,
                style: AppTypography.labelSmall.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
              onTap: () async {
                final resetQuestion = ctx.l10n.resetMemorizationPathQuestion;
                final resetDialog = [
                  ctx.l10n.resetMemorizationPathPreserveProgressDialog,
                  if (profile?.isGuardianLinked == true)
                    ctx.l10n.resetPathUnlinksGuardianWarning,
                ].join('\n\n');
                final cancelLabel = ctx.l10n.cancel;
                final resetLabel = ctx.l10n.reset;
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(
                      resetQuestion,
                      style: AppTypography.headlineSmall.copyWith(
                        fontFamily: 'Amiri',
                      ),
                    ),
                    content: Text(resetDialog),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(cancelLabel),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.warning,
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(resetLabel),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final repository = getIt<MemorizationPlusRepository>();
                  final profileResult = await repository
                      .getMemorizationProfile();
                  // A child leaving the kids track is a guardian action (the
                  // child could tap the dialog above themselves). Without a
                  // PIN yet, the guardian creates one first.
                  final requiresGuardianPin = profileResult.fold(
                    (_) => true,
                    (profile) => profile.isChild,
                  );
                  if (requiresGuardianPin) {
                    if (!context.mounted) return;
                    final isLinked = profileResult.fold(
                      (_) => true,
                      (profile) => profile.isGuardianLinked,
                    );
                    final guardianVerified = await ensureGuardianPin(
                      context,
                      allowRecovery: isLinked,
                      allowCreate: !isLinked,
                    );
                    if (!guardianVerified) return;
                  }
                  final result = await repository.resetMemorizationIdentity();
                  final failure = result.fold(
                    (failure) => failure,
                    (_) => null,
                  );
                  if (failure != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.localizedCubitMessage(failure.message),
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  getIt<MemorizationPathResolver>().notifyChanged();
                  if (context.mounted) {
                    context.pushReplacement(replacementLocation);
                  }
                }
              },
            ),
            if (canOpenGuardianArea)
              ListTile(
                key: const ValueKey('kids-open-guardian-area'),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TaliaIcons.guardian,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  ctx.l10n.guardianSessionTileTitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  ctx.l10n.guardianSessionTileSubtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                onTap: () {
                  if (!startTileAction()) return;
                  Navigator.pop(ctx);
                  _openGuardianArea(context, returnLocation);
                },
              ),
            if (canLinkGuardian)
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TaliaIcons.family,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  ctx.l10n.kidsLinkGuardianTileTitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  ctx.l10n.kidsLinkGuardianTileSubtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                onTap: () {
                  if (!startTileAction()) return;
                  Navigator.pop(ctx);
                  _openGuardianLinking(context);
                },
              ),
            if (profile?.isChild == true && profile!.isGuardianLinked)
              GuardianUnlinkTile(
                onTap: () {
                  Navigator.pop(ctx);
                  runGuardianUnlink(context);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Whether the profile is still an unlinked child. The sheet decided when it
/// opened; a link can arrive through sync while it is open, and a linked
/// child's guardian is remote, so the local guardian flows stop.
Future<bool> _isStillUnlinkedChild() async {
  final profile = (await getIt<MemorizationPlusRepository>()
          .getMemorizationProfile())
      .fold((_) => null, (profile) => profile);
  return profile != null && profile.isChild && !profile.isGuardianLinked;
}

/// Re-opens guardian linking for a child who skipped it, after the parent
/// PIN. A profile without a PIN creates one first.
Future<void> _openGuardianLinking(BuildContext context) async {
  final repository = getIt<MemorizationPlusRepository>();
  if (!await _isStillUnlinkedChild() || !context.mounted) return;
  final verified = await ensureGuardianPin(
    context,
    confirmLabel: context.l10n.confirm,
  );
  if (!verified) return;
  final result = await repository.reopenGuardianLinking();
  if (!context.mounted) return;
  result.fold(
    (failure) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.localizedCubitMessage(failure.message))),
    ),
    (_) {
      getIt<MemorizationPathResolver>().notifyChanged();
      context.push(AppRoutes.memorizationPlusGuardianLinking);
    },
  );
}

/// Opens the family dashboard for the guardian on the child's device, after
/// the PIN (created first when there is none), without changing the child's
/// identity.
Future<void> _openGuardianArea(
  BuildContext context,
  String returnLocation,
) async {
  if (!await _isStillUnlinkedChild() || !context.mounted) return;
  final verified = await ensureGuardianPin(
    context,
    confirmLabel: context.l10n.confirm,
  );
  if (!verified || !context.mounted) return;
  getIt<GuardianSessionController>().start(returnLocation: returnLocation);
  await context.push(AppRoutes.familyDashboard);
}

String _currentLocation(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.toString();
  } catch (_) {
    return AppRoutes.memorizationPlusKidsHome;
  }
}
