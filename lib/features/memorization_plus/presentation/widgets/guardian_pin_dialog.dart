import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import 'parent_pin_recovery_dialog.dart';

/// Asks for the guardian PIN on the child's device. With [allowRecovery] a
/// forgotten PIN can be replaced through the linked guardian, which proves
/// guardianship the same way.
Future<bool> verifyGuardianPin(
  BuildContext context, {
  String? confirmLabel,
  bool allowRecovery = false,
}) async {
  final verified = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _GuardianPinDialog(
      confirmLabel: confirmLabel,
      allowRecovery: allowRecovery,
    ),
  );
  return verified == true;
}

class _GuardianPinDialog extends StatefulWidget {
  const _GuardianPinDialog({this.confirmLabel, this.allowRecovery = false});

  /// Defaults to the reset label used by the path-reset flow.
  final String? confirmLabel;

  /// Recovery goes through the linked guardian, so only a linked child has it.
  final bool allowRecovery;

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
    final result = await getIt<MemorizationPlusRepository>().verifyParentPin(
      pin,
    );
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

  Future<void> _recover() async {
    final changed = await showParentPinRecoveryDialog(context);
    if (changed && mounted) Navigator.pop(context, true);
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
        if (widget.allowRecovery)
          TextButton(
            key: const ValueKey('guardian-pin-forgot'),
            onPressed: _isSubmitting ? null : _recover,
            child: Text(context.l10n.parentDashboardForgotPin),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleConfirm,
          child: Text(widget.confirmLabel ?? context.l10n.reset),
        ),
      ],
    );
  }
}
