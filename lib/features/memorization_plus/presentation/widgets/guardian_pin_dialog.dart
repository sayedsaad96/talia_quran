import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import 'parent_pin_recovery_dialog.dart';

/// Guards a sensitive guardian action on the child's device.
///
/// The PIN is optional at child setup, but guardian actions always need one:
/// an existing PIN is verified, and when none exists yet the guardian creates
/// it here before the action continues. If the settings cannot be read the
/// PIN is asked for, so an error never opens the action.
///
/// Pass `allowCreate: false` for a child linked to a remote guardian: anyone
/// holding the device could create a PIN, so that guardian proves themselves
/// through recovery instead.
Future<bool> ensureGuardianPin(
  BuildContext context, {
  String? confirmLabel,
  bool allowRecovery = false,
  bool allowCreate = true,
}) async {
  final settings = (await getIt<MemorizationPlusRepository>()
          .getParentSettings())
      .fold((_) => null, (settings) => settings);
  if (!context.mounted) return false;
  if (settings == null || settings.hasPin || !allowCreate) {
    return verifyGuardianPin(
      context,
      confirmLabel: confirmLabel,
      allowRecovery: allowRecovery,
    );
  }
  return await createGuardianPin(context) != null;
}

/// Asks the guardian to create a PIN and saves it. Returns the new PIN, or
/// null when the guardian cancels.
Future<String?> createGuardianPin(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CreateGuardianPinDialog(),
  );
}

class _CreateGuardianPinDialog extends StatefulWidget {
  const _CreateGuardianPinDialog();

  @override
  State<_CreateGuardianPinDialog> createState() =>
      _CreateGuardianPinDialogState();
}

class _CreateGuardianPinDialogState extends State<_CreateGuardianPinDialog> {
  late final TextEditingController _pin;
  late final TextEditingController _confirm;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pin = TextEditingController();
    _confirm = TextEditingController();
  }

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    final pin = _pin.text.trim();
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _error = context.l10n.parentDashboardPinInvalid);
      return;
    }
    if (pin != _confirm.text.trim()) {
      setState(() => _error = context.l10n.parentDashboardPinMismatch);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final repository = getIt<MemorizationPlusRepository>();
    // Another dialog (a double tap) may have created a PIN while this one was
    // open. Creating must never replace an existing PIN, so this dialog
    // closes as cancelled; an unreadable setting counts as a PIN.
    final alreadySet = (await repository.getParentSettings()).fold(
      (_) => true,
      (settings) => settings.hasPin,
    );
    if (!mounted) return;
    if (alreadySet) {
      Navigator.pop(context);
      return;
    }
    final result = await repository.setParentPin(pin);
    if (!mounted) return;
    if (result.isRight()) {
      Navigator.pop(context, pin);
    } else {
      setState(() {
        _isSubmitting = false;
        _error = context.l10n.errorUnknownMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.parentDashboardCreatePinTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.guardianPinCreateReason),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('guardian-pin-create'),
              controller: _pin,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                counterText: '',
                labelText: 'PIN',
              ),
            ),
            TextField(
              key: const ValueKey('guardian-pin-create-confirm'),
              controller: _confirm,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                counterText: '',
                labelText: context.l10n.parentDashboardPinConfirm,
                errorText: _error,
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('guardian-pin-create-save'),
          onPressed: _isSubmitting ? null : _save,
          child: Text(context.l10n.parentDashboardSavePinButton),
        ),
      ],
    );
  }
}

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
