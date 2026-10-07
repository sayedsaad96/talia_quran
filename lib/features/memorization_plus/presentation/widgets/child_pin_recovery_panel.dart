import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/repositories/parent_pin_recovery_repository.dart';
import '../../domain/usecases/parent_pin_recovery_usecases.dart';
import '../cubits/pin_recovery_approval_cubit.dart';

/// Guardian: open PIN-change requests from a linked child's device. Hidden
/// when there are none.
class ChildPinRecoveryPanel extends StatelessWidget {
  const ChildPinRecoveryPanel({super.key, required this.childUserId});

  final String childUserId;

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<ParentPinRecoveryUsecase>()) {
      return const SizedBox.shrink();
    }
    return BlocProvider(
      create: (_) => PinRecoveryApprovalCubit(
        getIt<ParentPinRecoveryUsecase>(),
        childUserId,
      )..load(),
      child: const ChildPinRecoveryView(),
    );
  }
}

class ChildPinRecoveryView extends StatelessWidget {
  const ChildPinRecoveryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PinRecoveryApprovalCubit, PinRecoveryApprovalState>(
      listenWhen: (previous, current) =>
          (current.approvedCode != null &&
              previous.approvedCode != current.approvedCode) ||
          current.errorEventId != previous.errorEventId,
      listener: _onChange,
      builder: (context, state) {
        if (state.requests.isEmpty) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Container(
          key: const ValueKey('child-pin-recovery-panel'),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.pinRecoveryRequestTitle,
                style: AppTypography.titleSmall.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.pinRecoveryRequestBody,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                key: const ValueKey('child-pin-recovery-approve'),
                onPressed: state.busy
                    ? null
                    : () => context.read<PinRecoveryApprovalCubit>().approve(
                        state.requests.first.id,
                      ),
                icon: const Icon(TaliaIcons.key),
                label: Text(context.l10n.pinRecoveryApproveAction),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onChange(
    BuildContext context,
    PinRecoveryApprovalState state,
  ) async {
    final cubit = context.read<PinRecoveryApprovalCubit>();
    final code = state.approvedCode;
    if (code == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(context.localizedCubitMessage(state.errorCode ?? '')),
        ),
      );
      return;
    }
    final request = state.requests.isEmpty ? null : state.requests.first;
    await showDialog<void>(
      context: context,
      builder: (_) => _CodeDialog(code: code, request: request),
    );
    cubit.dismissCode();
  }
}

class _CodeDialog extends StatelessWidget {
  const _CodeDialog({required this.code, required this.request});

  final String code;
  final PinRecoveryChallenge? request;

  @override
  Widget build(BuildContext context) {
    final expiresAt = request?.expiresAt;
    return AlertDialog(
      title: Text(context.l10n.pinRecoveryCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(
              _grouped(code),
              key: const ValueKey('child-pin-recovery-code'),
              textAlign: TextAlign.center,
              style: AppTypography.headlineSmall.copyWith(letterSpacing: 2),
            ),
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.pinRecoveryCodeBody(_time(context, expiresAt)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.close),
        ),
      ],
    );
  }

  static String _grouped(String code) => [
    for (var i = 0; i < code.length; i += 4)
      code.substring(i, (i + 4).clamp(0, code.length)),
  ].join('-');

  static String _time(BuildContext context, DateTime at) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return context.digitText(DateFormat.jm(locale).format(at.toLocal()));
  }
}
