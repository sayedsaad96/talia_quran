import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

Future<void> showMemorizationPathSettingsSheet(
  BuildContext context, {
  required bool isDark,
  String replacementLocation = AppRoutes.memorizationPlus,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground,
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
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
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
                child: const Icon(
                  Icons.restart_alt_rounded,
                  color: AppColors.warning,
                ),
              ),
              title: Text(
                ctx.l10n.resetMemorizationPathTileTitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                ctx.l10n.resetMemorizationPathPreserveProgressDesc,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              onTap: () async {
                final resetQuestion = ctx.l10n.resetMemorizationPathQuestion;
                final resetDialog =
                    ctx.l10n.resetMemorizationPathPreserveProgressDialog;
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
                  final requiresGuardianPin = profileResult.fold(
                    (_) => true,
                    // Only require PIN when a guardian is linked on another
                    // device. A standalone child profile (no linked guardian)
                    // does not need PIN verification — the parent confirmed
                    // the reset in the dialog above.
                    (profile) => profile.isChild && profile.isGuardianLinked,
                  );
                  if (requiresGuardianPin) {
                    if (!context.mounted) return;
                    final guardianVerified = await _verifyGuardianPin(context);
                    if (!guardianVerified) return;
                  }
                  final result = await repository.resetMemorizationIdentity();
                  final failure = result.fold(
                    (failure) => failure,
                    (_) => null,
                  );
                  if (failure != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(failure.message)));
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
          ],
        ),
      ),
    ),
  );
}

Future<bool> _verifyGuardianPin(BuildContext context) async {
  final verified = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _GuardianPinDialog(),
  );
  return verified == true;
}

class _GuardianPinDialog extends StatefulWidget {
  const _GuardianPinDialog();

  @override
  State<_GuardianPinDialog> createState() => _GuardianPinDialogState();
}

class _GuardianPinDialogState extends State<_GuardianPinDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;
    final pin = _controller.text.trim();
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _error = context.l10n.parentDashboardPinInvalid);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final result =
        await getIt<MemorizationPlusRepository>().verifyParentPin(pin);
    final isValid = result.getOrElse(() => false);
    if (!mounted) return;
    if (isValid) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isSubmitting = false;
        _error = context.l10n.parentDashboardPinIncorrect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.parentDashboardEnterPinTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.parentDashboardPinHelp),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                counterText: '',
                labelText: 'PIN',
                errorText: _error,
              ),
              onSubmitted: (_) => _handleConfirm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleConfirm,
          child: Text(context.l10n.reset),
        ),
      ],
    );
  }
}

