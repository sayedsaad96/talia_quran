import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../domain/usecases/parent_pin_recovery_usecases.dart';
import '../cubits/pin_recovery_request_cubit.dart';

/// Child device: replaces a forgotten guardian PIN with the linked guardian's
/// one-time code. Returns true once the new PIN is saved.
Future<bool> showParentPinRecoveryDialog(BuildContext context) async {
  final changed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (_) =>
          PinRecoveryRequestCubit(getIt<ParentPinRecoveryUsecase>())..start(),
      child: const ParentPinRecoveryDialog(),
    ),
  );
  return changed == true;
}

class ParentPinRecoveryDialog extends StatefulWidget {
  const ParentPinRecoveryDialog({super.key});

  @override
  State<ParentPinRecoveryDialog> createState() =>
      _ParentPinRecoveryDialogState();
}

class _ParentPinRecoveryDialogState extends State<ParentPinRecoveryDialog> {
  final _code = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _submit() => context.read<PinRecoveryRequestCubit>().submit(
    code: _code.text,
    newPin: _pin.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinRecoveryRequestCubit, PinRecoveryRequestState>(
      listenWhen: (_, state) => state.status == PinRecoveryRequestStatus.done,
      listener: (context, _) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(context.l10n.pinRecoveryDone)));
        Navigator.pop(context, true);
      },
      builder: (context, state) {
        final canSubmit =
            state.challenge != null &&
            state.status != PinRecoveryRequestStatus.submitting;
        return AlertDialog(
          title: Text(context.l10n.pinRecoveryTitle),
          content: SingleChildScrollView(child: _content(context, state)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            if (state.challenge != null)
              FilledButton(
                key: const ValueKey('pin-recovery-submit'),
                onPressed: canSubmit ? _submit : null,
                child: Text(context.l10n.confirm),
              ),
          ],
        );
      },
    );
  }

  Widget _content(BuildContext context, PinRecoveryRequestState state) {
    if (state.status == PinRecoveryRequestStatus.requesting) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final error = switch (state.status) {
      PinRecoveryRequestStatus.wrongCode => context.l10n.pinRecoveryWrongCode,
      PinRecoveryRequestStatus.pinInvalid =>
        context.l10n.parentDashboardPinInvalid,
      PinRecoveryRequestStatus.failed => context.localizedCubitMessage(
        state.errorCode ?? '',
      ),
      _ => null,
    };
    if (state.challenge == null) {
      return Text(error ?? '', key: const ValueKey('pin-recovery-error'));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.pinRecoveryInstructions),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('pin-recovery-code'),
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          textDirection: TextDirection.ltr,
          autocorrect: false,
          maxLength: 14,
          decoration: InputDecoration(
            counterText: '',
            labelText: context.l10n.pinRecoveryCodeLabel,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const ValueKey('pin-recovery-new-pin'),
          controller: _pin,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: InputDecoration(
            counterText: '',
            labelText: context.l10n.pinRecoveryNewPinLabel,
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            key: const ValueKey('pin-recovery-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
