import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import 'parent_pin_recovery_dialog.dart';

enum GuardianPinOutcome { cancelled, verified, skipped }

class GuardianPinDecision {
  const GuardianPinDecision(this.outcome, [this.pin]);
  final GuardianPinOutcome outcome;
  final String? pin;
  bool get proceeds => outcome != GuardianPinOutcome.cancelled;
}

/// Explicitly optional authorization. Skipping never verifies or writes a PIN.
Future<GuardianPinDecision> optionalGuardianPin(
  BuildContext context, {
  String? confirmLabel,
  bool allowRecovery = false,
  bool allowCreate = true,
  bool Function()? isScopeValid,
  Future<bool> Function()? canCreatePin,
}) async {
  final settings =
      (await getIt<MemorizationPlusRepository>().getParentSettings()).fold(
        (_) => null,
        (settings) => settings,
      );
  if (!context.mounted || !(isScopeValid?.call() ?? true)) {
    return const GuardianPinDecision(GuardianPinOutcome.cancelled);
  }
  final decision = await showDialog<GuardianPinDecision>(
    context: context,
    barrierDismissible: false,
    builder: (_) => settings != null && !settings.hasPin && allowCreate
        ? _CreateGuardianPinDialog(
            isScopeValid: isScopeValid,
            canCreatePin: canCreatePin,
            optional: true,
          )
        : _GuardianPinDialog(
            confirmLabel: confirmLabel,
            allowRecovery: allowRecovery,
            optional: true,
          ),
  );
  if (!context.mounted || !(isScopeValid?.call() ?? true)) {
    return const GuardianPinDecision(GuardianPinOutcome.cancelled);
  }
  return decision ?? const GuardianPinDecision(GuardianPinOutcome.cancelled);
}

/// Requires PIN creation or verification for a guardian linking operation.
/// Linked devices may use account recovery instead of creating a local PIN.
Future<bool> ensureGuardianPin(
  BuildContext context, {
  String? confirmLabel,
  bool allowRecovery = false,
  bool allowCreate = true,
  bool Function()? isScopeValid,
  Future<bool> Function()? canCreatePin,
}) async {
  final settings =
      (await getIt<MemorizationPlusRepository>().getParentSettings()).fold(
        (_) => null,
        (settings) => settings,
      );
  if (!context.mounted || !(isScopeValid?.call() ?? true)) return false;
  if (settings == null || settings.hasPin || !allowCreate) {
    return verifyGuardianPin(
      context,
      confirmLabel: confirmLabel,
      allowRecovery: allowRecovery,
    );
  }
  return await createGuardianPin(
        context,
        isScopeValid: isScopeValid,
        canCreatePin: canCreatePin,
      ) !=
      null;
}

/// Asks the guardian to create a PIN and saves it. Returns the new PIN, or
/// null when the guardian cancels.
Future<String?> createGuardianPin(
  BuildContext context, {
  bool Function()? isScopeValid,
  Future<bool> Function()? canCreatePin,
}) {
  return showDialog<GuardianPinDecision>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CreateGuardianPinDialog(
      isScopeValid: isScopeValid,
      canCreatePin: canCreatePin,
    ),
  ).then((decision) => decision?.pin);
}

class _CreateGuardianPinDialog extends StatefulWidget {
  const _CreateGuardianPinDialog({
    this.isScopeValid,
    this.canCreatePin,
    this.optional = false,
  });
  final bool optional;
  final bool Function()? isScopeValid;
  final Future<bool> Function()? canCreatePin;

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
    if (alreadySet || !(widget.isScopeValid?.call() ?? true)) {
      Navigator.pop(context);
      return;
    }
    final allowed = await (widget.canCreatePin?.call() ?? Future.value(true));
    if (!mounted) return;
    if (!allowed || !(widget.isScopeValid?.call() ?? true)) {
      Navigator.pop(context);
      return;
    }
    final result = await repository.setParentPin(pin);
    if (!mounted) return;
    if (result.isRight()) {
      Navigator.pop(
        context,
        GuardianPinDecision(GuardianPinOutcome.verified, pin),
      );
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
        if (widget.optional)
          TextButton(
            key: const ValueKey('guardian-pin-skip'),
            onPressed: _isSubmitting
                ? null
                : () => Navigator.pop(
                    context,
                    const GuardianPinDecision(GuardianPinOutcome.skipped),
                  ),
            child: Text(context.l10n.skip),
          ),
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
  final verified = await showDialog<GuardianPinDecision>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _GuardianPinDialog(
      confirmLabel: confirmLabel,
      allowRecovery: allowRecovery,
    ),
  );
  return verified?.outcome == GuardianPinOutcome.verified;
}

class _GuardianPinDialog extends StatefulWidget {
  const _GuardianPinDialog({
    this.confirmLabel,
    this.allowRecovery = false,
    this.optional = false,
  });
  final bool optional;

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
      Navigator.pop(
        context,
        GuardianPinDecision(GuardianPinOutcome.verified, pin),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _error = context.l10n.parentDashboardPinIncorrect;
      });
    }
  }

  Future<void> _recover() async {
    final changed = await showParentPinRecoveryDialog(context);
    if (changed && mounted) {
      Navigator.pop(
        context,
        const GuardianPinDecision(GuardianPinOutcome.verified),
      );
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
            Text(
              widget.optional
                  ? context.l10n.parentDashboardPinHelp
                  : context.l10n.guardianPinCreateReason,
            ),
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
        if (widget.optional)
          TextButton(
            key: const ValueKey('guardian-pin-skip'),
            onPressed: _isSubmitting
                ? null
                : () => Navigator.pop(
                    context,
                    const GuardianPinDecision(GuardianPinOutcome.skipped),
                  ),
            child: Text(context.l10n.skip),
          ),
        if (widget.allowRecovery)
          TextButton(
            key: const ValueKey('guardian-pin-forgot'),
            onPressed: _isSubmitting ? null : _recover,
            child: Text(context.l10n.parentDashboardForgotPin),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
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
